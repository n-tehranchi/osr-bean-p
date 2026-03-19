#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# submit-all-sims-runai.sh
# Loops through all 39 filenames in inputs/Identifiers.txt and submits each
# as a separate Run:ai training job.
# ---------------------------------------------------------------------------

# --- Configuration (override via env or .env file) ---
PROJECT="${RUNAI_PROJECT:-busch-lab}"
IMAGE="${DOCKER_IMAGE:-nntehranchi/osr-bean-p:latest}"
CPU="${CPU_COUNT:-4}"
MEMORY="${MEMORY_LIMIT:-8G}"
OUTPUT_PATH="${OUTPUT_PATH:-/home/jovyan/work/outputs/bean-p/}"
NAMESPACE="${RUNAI_NAMESPACE:-runai-busch-lab}"
DRY_RUN="${DRY_RUN:-false}"

# --- Validate GITHUB_TOKEN ---
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "ERROR: GITHUB_TOKEN env var is not set. Export it before running this script."
    exit 1
fi

# --- Load .env if present ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
if [[ -f "${ENV_FILE}" ]]; then
    echo "Loading config from ${ENV_FILE}"
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
fi

# --- Locate Identifiers.txt ---
ID_FILE="${SCRIPT_DIR}/../inputs/Identifiers.txt"
if [[ ! -f "${ID_FILE}" ]]; then
    echo "ERROR: ${ID_FILE} not found."
    exit 1
fi

TOTAL=$(wc -l < "${ID_FILE}" | tr -d ' ')
SUBMITTED=0
FAILED=0
SKIPPED=0

echo "============================================"
echo "OpenSimRoot — Submit All Bean P Sims"
echo "  Project:    ${PROJECT}"
echo "  Image:      ${IMAGE}"
echo "  Resources:  ${CPU} CPU, ${MEMORY} RAM"
echo "  Output dir: ${OUTPUT_PATH}"
echo "  Total jobs: ${TOTAL}"
echo "  Dry run:    ${DRY_RUN}"
echo "============================================"
echo ""

while IFS= read -r filename || [[ -n "${filename}" ]]; do
    # Skip blank lines
    [[ -z "${filename}" ]] && continue

    # Strip .xml extension and build a valid Run:ai job name
    # (lowercase alphanumeric + hyphens only, <40 chars)
    # e.g. bean_advanced_p1.00 -> bp-adv-p100
    basename="${filename%.xml}"
    short_pheno="${basename#bean_}"          # advanced_p1.00
    pheno="${short_pheno%%_*}"              # advanced
    plevel="${short_pheno#*_p}"             # 1.00
    plevel="${plevel//./}"                  # 100 (remove dots)
    case "${pheno}" in
        advanced)     ptag="adv" ;;
        intermediate) ptag="int" ;;
        reduced)      ptag="red" ;;
        *)            ptag="${pheno:0:3}" ;;
    esac
    job_name="bp-${ptag}-p${plevel}"

    CMD=(
        runai training submit "${job_name}"
        --project "${PROJECT}"
        --image "${IMAGE}"
        --image-pull-policy Always
        --cpu-core-request "${CPU}"
        --cpu-memory-request "${MEMORY}"
        -e INPUT_FILE="${filename}"
        -e GITHUB_TOKEN="${GITHUB_TOKEN}"
        -e OUTPUT_PATH="${OUTPUT_PATH}"
    )

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "[dry-run] ${CMD[*]}"
        ((SKIPPED++))
    else
        echo "Submitting job: ${job_name} (${filename})"
        if "${CMD[@]}" 2>&1; then
            echo "  -> submitted OK"
            ((SUBMITTED++))
        else
            echo "  -> FAILED"
            ((FAILED++))
        fi
    fi
done < "${ID_FILE}"

echo ""
echo "============================================"
echo "Done."
if [[ "${DRY_RUN}" == "true" ]]; then
    echo "  Dry-run jobs previewed: ${SKIPPED}"
else
    echo "  Submitted: ${SUBMITTED}"
    echo "  Failed:    ${FAILED}"
fi
echo "============================================"

if [[ "${FAILED}" -gt 0 ]]; then
    echo "WARNING: ${FAILED} job(s) failed to submit."
    exit 1
fi
