# OpenSimRoot Bean Phosphorus Pipeline

Containerized pipeline for running [OpenSimRoot](https://github.com/n-tehranchi/OpenSimRoot) bean root-architecture simulations at scale on a Run:ai (Kubernetes) cluster. Based on Strock et al. (2018) *Plant Physiology* 176:691–703: "Reduction in Root Secondary Growth as a Strategy for Phosphorus Acquisition."

## What this does

- Builds OpenSimRoot from source inside a Docker container
- Generates 39 XML input files (3 secondary-growth phenotypes × 13 soil P levels)
- Runs root-architecture simulations and pushes results to GitHub
- Submits batch jobs to Run:ai under the `busch-lab` project

## Quick start

```bash
# 1. Generate the 39 input XMLs (if not already present)
python3 scripts/generate_inputs.py

# 2. Build the Docker image
docker build -t osr-bean-p .

# 3. Run a single simulation locally
docker run --rm \
  -e INPUT_FILE=bean_advanced_p1.00.xml \
  -v $(pwd)/output:/sim/output \
  osr-bean-p

# 4. Submit all 39 jobs to Run:ai
cp .env.example .env   # edit with your cluster settings
bash scripts/submit-single-job-runai.sh
```

See [QUICKSTART.md](QUICKSTART.md) for detailed setup instructions.

## Phenotypes (3)

| # | Phenotype | Secondary growth multiplier | Description |
|---|-----------|----------------------------|-------------|
| 1 | `advanced` | 1.0 | Wild-type / full secondary growth (reference) |
| 2 | `intermediate` | 0.5 | 50% secondary growth rate |
| 3 | `reduced` | 0.0 | No secondary growth |

## Phosphorus levels (13)

| P (kg/ha) | P (umol/ml) | Description |
|-----------|-------------|-------------|
| 0.17 | 0.00274 | Severely deficient |
| 0.25 | 0.00404 | |
| 0.50 | 0.00807 | |
| 0.75 | 0.01211 | |
| 1.00 | 0.01614 | Low |
| 1.50 | 0.02422 | |
| 2.00 | 0.03229 | |
| 2.50 | 0.04036 | Moderate |
| 3.00 | 0.04843 | |
| 3.50 | 0.05651 | |
| 4.00 | 0.06458 | |
| 4.50 | 0.07265 | |
| 5.00 | 0.08072 | Adequate |

Conversion: `C (umol/ml) = P_rate (kg/ha) × 10 / (30.97 × 20)`, assuming 20 cm topsoil mixing depth.

## Project structure

```
Dockerfile                          # Multi-stage build for OpenSimRoot
inputs/
  SimRoot4_bean_carioca.xml         # Template: advanced secondary growth
  SimRoot4_bean_carioca_reduced...  # Template: reduced secondary growth
  bean_advanced_p0.17.xml           # Generated input (39 total)
  ...
  Identifiers.txt                   # List of all 39 generated filenames
scripts/
  generate_inputs.py                # Generates 39 XMLs from templates
  entrypoint.sh                     # Container entrypoint
  run-all-sims.sh                   # Runs all 39 simulations sequentially
  submit-single-job-runai.sh        # Submits one Run:ai job
.env.example                        # Configuration template
output/                             # Mount point for simulation results
```

## Configuration

Copy `.env.example` to `.env` and edit:

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_IMAGE` | `nntehranchi/osr-bean-p:latest` | Container image |
| `RUNAI_PROJECT` | `busch-lab` | Run:ai project name |
| `CPU_COUNT` | `2` | CPUs per job |
| `MEMORY_LIMIT` | `4Gi` | Memory per job |
| `GPU_COUNT` | `0` | GPUs per job |
| `PVC_NAME` | `opensimroot-data` | Persistent volume claim name |
| `DRY_RUN` | `false` | Preview commands without submitting |

## License

See the [OpenSimRoot repository](https://github.com/n-tehranchi/OpenSimRoot) for license details.
