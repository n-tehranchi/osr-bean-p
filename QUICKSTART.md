# Quick Start Guide

## Prerequisites

- Python 3.6+ (for input generation)
- Docker installed and running
- (For cluster submission) `runai` CLI installed and authenticated
- (For cluster submission) Access to the `busch-lab` Run:ai project

## 1. Generate input files

```bash
python3 scripts/generate_inputs.py
```

This reads the two template XMLs in `inputs/` and creates 39 simulation input files (3 phenotypes × 13 P levels) plus `Identifiers.txt`.

## 2. Build the Docker image

```bash
docker build -t osr-bean-p .
```

This clones OpenSimRoot, compiles it from source, and creates a slim runtime image with the 39 input XMLs bundled in.

## 3. Run a single simulation locally

```bash
docker run --rm \
  -e INPUT_FILE=bean_advanced_p1.00.xml \
  -v $(pwd)/output:/sim/output \
  osr-bean-p
```

Results appear in `output/bean_advanced_p1.00/`.

## 4. Run all 39 simulations locally

```bash
docker run --rm \
  -v $(pwd)/output:/sim/output \
  osr-bean-p bash /usr/local/bin/run-all-sims.sh
```

To also push results to GitHub, set the `GITHUB_TOKEN` env var:

```bash
docker run --rm \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -v $(pwd)/output:/sim/output \
  osr-bean-p bash /usr/local/bin/run-all-sims.sh
```

## 5. Submit all jobs to Run:ai

```bash
# Copy and edit the config
cp .env.example .env
# Edit .env with your cluster settings

# Preview what will be submitted (dry run)
DRY_RUN=true bash scripts/submit-single-job-runai.sh

# Submit for real
export GITHUB_TOKEN="your-token-here"
bash scripts/submit-single-job-runai.sh
```

This submits one job that runs all 39 simulations sequentially.

## 6. Monitor jobs

```bash
# List all running jobs
runai list jobs --project busch-lab

# Check the job
runai describe job osr-bean-p-all --project busch-lab

# View logs
runai logs osr-bean-p-all --project busch-lab
```

## 7. Collect results

Results are written to the PVC at `/sim/output/<basename>/`. Retrieve them from the persistent volume or copy from a running pod:

```bash
kubectl cp <pod-name>:/sim/output ./results -n runai-busch-lab
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "INPUT_FILE env var is not set" | Set `INPUT_FILE` to the XML filename (e.g., `bean_advanced_p1.00.xml`) |
| "No XML input file found" | Ensure input files are in `inputs/` and bundled in the image, or mount via `-v` |
| Job OOMKilled | Increase `MEMORY_LIMIT` in `.env` |
| `runai` command not found | Install the Run:ai CLI and authenticate with your cluster |
| "GITHUB_TOKEN not set" | Export `GITHUB_TOKEN` to push results; the simulation still runs without it |
