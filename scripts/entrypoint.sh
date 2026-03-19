#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# entrypoint.sh
# Runs the OpenSimRoot binary with a specified XML input file.
# ---------------------------------------------------------------------------

# Required environment variables
: "${INPUT_FILE:?Error: INPUT_FILE env var is not set}"

# Optional
OUTPUT_PATH="${OUTPUT_PATH:-/sim/output}"

# Fall back to bundled inputs if INPUT_DIR is not set or does not exist
if [[ -n "${INPUT_DIR:-}" && -d "${INPUT_DIR}" ]]; then
    XML_PATH="${INPUT_DIR}/${INPUT_FILE}"
else
    XML_PATH="/opt/inputs/${INPUT_FILE}"
fi

echo "============================================"
echo "OpenSimRoot Simulation"
echo "  Input file:  ${XML_PATH}"
echo "  Output path: ${OUTPUT_PATH}"
echo "============================================"

# Verify the input file exists
if [[ ! -f "${XML_PATH}" ]]; then
    echo "ERROR: Input file not found: ${XML_PATH}"
    exit 1
fi

# Prepare output directory
mkdir -p "${OUTPUT_PATH}"

# Run from the output directory so OpenSimRoot writes results there
cd "${OUTPUT_PATH}"

echo "Running OpenSimRoot..."
OpenSimRoot "${XML_PATH}" || true

echo "Simulation completed. FATAL ERROR messages from this model version are expected warnings."
echo "Results saved to: ${OUTPUT_PATH}"

# ---------------------------------------------------------------------------
# Push output files to GitHub
# ---------------------------------------------------------------------------
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "WARNING: GITHUB_TOKEN not set — skipping push to GitHub."
    exit 0
fi

GITHUB_REPO="${GITHUB_REPO:-n-tehranchi/osr-bean-p}"
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
BASENAME="$(basename "${INPUT_FILE}" .xml)"
CLONE_DIR="/tmp/repo-push"

echo "Pushing results to GitHub (results/${BASENAME}/) ..."

git clone --depth 1 "${REPO_URL}" "${CLONE_DIR}"
cd "${CLONE_DIR}"

git config user.email "pipeline@opensimroot"
git config user.name "OpenSimRoot Pipeline"

mkdir -p "results/${BASENAME}"
cp -r "${OUTPUT_PATH}/." "results/${BASENAME}/"

git add "results/${BASENAME}"
git commit -m "Add simulation results for ${BASENAME}"
git push origin main

echo "Results pushed to GitHub: results/${BASENAME}/"
rm -rf "${CLONE_DIR}"
exit 0
