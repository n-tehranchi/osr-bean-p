#!/usr/bin/env bash
set -uo pipefail

# ---------------------------------------------------------------------------
# run-all-sims.sh
# Runs all 39 simulations (3 phenotypes × 13 P levels) inside a single
# container, then pushes all results to GitHub in one commit.
# Reads filenames from Identifiers.txt.
# ---------------------------------------------------------------------------

OUTPUT_PATH="${OUTPUT_PATH:-/sim/output}"
INPUT_DIR="${INPUT_DIR:-/opt/inputs}"
IDENTIFIERS="${INPUT_DIR}/Identifiers.txt"

if [[ ! -f "${IDENTIFIERS}" ]]; then
    echo "ERROR: Identifiers.txt not found at ${IDENTIFIERS}"
    exit 1
fi

TOTAL=$(wc -l < "${IDENTIFIERS}" | tr -d ' ')

echo "============================================"
echo "OpenSimRoot — Run All Bean P Simulations"
echo "  Input dir:    ${INPUT_DIR}"
echo "  Output dir:   ${OUTPUT_PATH}"
echo "  Identifiers:  ${IDENTIFIERS}"
echo "  Total sims:   ${TOTAL}"
echo "============================================"
echo ""

SUCCEEDED=0
FAILED=0
COUNT=0

while IFS= read -r XML_FILE || [[ -n "${XML_FILE}" ]]; do
    # Skip empty lines
    [[ -z "${XML_FILE}" ]] && continue

    ((COUNT++))
    XML_PATH="${INPUT_DIR}/${XML_FILE}"
    BASENAME="${XML_FILE%.xml}"
    SIM_OUTPUT="${OUTPUT_PATH}/${BASENAME}"

    echo "--------------------------------------------"
    echo "[${COUNT}/${TOTAL}] ${XML_FILE}"

    if [[ ! -f "${XML_PATH}" ]]; then
        echo "  WARNING: Input file not found — skipping."
        ((FAILED++))
        continue
    fi

    mkdir -p "${SIM_OUTPUT}"

    # Run from the output directory so OpenSimRoot writes results there
    # Use || true so a non-zero exit never stops the loop
    (cd "${SIM_OUTPUT}" && OpenSimRoot "${XML_PATH}") || true
    echo "  DONE"
    ((SUCCEEDED++))

done < "${IDENTIFIERS}"

echo ""
echo "============================================"
echo "All simulations finished."
echo "  Succeeded: ${SUCCEEDED}"
echo "  Skipped:   ${FAILED}"
echo "============================================"

# ---------------------------------------------------------------------------
# Push all results to GitHub in a single commit
# ---------------------------------------------------------------------------
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "WARNING: GITHUB_TOKEN not set — skipping push to GitHub."
    exit 0
fi

GITHUB_REPO="${GITHUB_REPO:-n-tehranchi/osr-bean-p}"
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
CLONE_DIR="/tmp/repo-push"

echo ""
echo "Pushing all results to GitHub ..."

rm -rf "${CLONE_DIR}"
git clone --depth 1 "${REPO_URL}" "${CLONE_DIR}"
cd "${CLONE_DIR}"

git config user.email "pipeline@opensimroot"
git config user.name "OpenSimRoot Pipeline"

mkdir -p results
cp -r "${OUTPUT_PATH}/." results/

git add results/
git commit -m "Add simulation results for all ${TOTAL} bean P runs"
git push origin main

echo "Results pushed to GitHub: results/"
rm -rf "${CLONE_DIR}"
echo "Done."
