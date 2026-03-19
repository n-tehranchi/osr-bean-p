#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# submit-single-job-runai.sh
# Submits ONE Run:ai training job that runs all 39 bean P simulations
# sequentially using scripts/run-all-sims.sh inside the container.
# ---------------------------------------------------------------------------

# --- Configuration (override via env or .env file) ---
PROJECT="${RUNAI_PROJECT:-busch-lab}"
IMAGE="${DOCKER_IMAGE:-nntehranchi/osr-bean-p:latest}"
GPU="${GPU_COUNT:-0}"
CPU="${CPU_COUNT:-2}"
MEMORY="${MEMORY_LIMIT:-4Gi}"
OUTPUT_PATH="${OUTPUT_PATH:-/sim/output}"
NAMESPACE="${RUNAI_NAMESPACE:-runai-busch-lab}"
JOB_NAME="${JOB_NAME:-osr-bean-p-all}"
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

echo "============================================"
echo "OpenSimRoot — Submit Single Job (All Bean P Sims)"
echo "  Job name:   ${JOB_NAME}"
echo "  Project:    ${PROJECT}"
echo "  Image:      ${IMAGE}"
echo "  Resources:  ${CPU} CPU, ${MEMORY} RAM, ${GPU} GPU"
echo "  Output dir: ${OUTPUT_PATH}"
echo "  Dry run:    ${DRY_RUN}"
echo "============================================"
echo ""

CMD=(
    runai training submit "${JOB_NAME}"
    --project "${PROJECT}"
    --image "${IMAGE}"
    --image-pull-policy Always
    --cpu-core-request "${CPU}"
    --cpu-memory-request "${MEMORY}"
    -e OUTPUT_PATH="${OUTPUT_PATH}"
    -e GITHUB_TOKEN="${GITHUB_TOKEN}"
    --command -- bash /usr/local/bin/run-all-sims.sh
)

if [[ "${GPU}" -gt 0 ]]; then
    CMD+=(--gpu "${GPU}")
fi

if [[ "${DRY_RUN}" == "true" ]]; then
    echo "[dry-run] ${CMD[*]}"
else
    echo "Submitting job..."
    if "${CMD[@]}" 2>&1; then
        echo "Job '${JOB_NAME}' submitted successfully."
    else
        echo "ERROR: Job submission failed."
        exit 1
    fi
fi
