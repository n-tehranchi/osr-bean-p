# CLAUDE.md — OpenSimRoot Bean Phosphorus Pipeline

## Project overview

This repo containerizes [OpenSimRoot](https://github.com/n-tehranchi/OpenSimRoot) and orchestrates bean (*Phaseolus vulgaris* cv. Carioca) phosphorus-acquisition simulations on a Run:ai (Kubernetes) cluster under the **busch-lab** project. Based on Strock et al. (2018) *Plant Physiology* 176:691–703, it explores how reduction in root secondary growth affects phosphorus acquisition across a gradient of soil P availability.

## Experimental design

**3 phenotypes × 13 P levels = 39 simulations**

| Factor | Levels |
|--------|--------|
| Secondary growth | advanced (multiplier 1.0), intermediate (0.5), reduced (0.0) |
| Soil P (kg/ha) | 0.17, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0 |

P concentrations are converted from kg/ha to umol/ml assuming 20 cm topsoil mixing depth (see `scripts/generate_inputs.py`).

## Repo structure

```
Dockerfile                      # Multi-stage build: compiles OpenSimRoot, produces slim runtime image
inputs/                         # 39 generated XML files + Identifiers.txt + 2 template XMLs
scripts/
  generate_inputs.py            # Generates the 39 XML input files from templates
  entrypoint.sh                 # Container entrypoint — reads INPUT_FILE env var, runs simulator
  run-all-sims.sh               # Loops through all 39 files and runs each sequentially
  submit-single-job-runai.sh    # Submits one Run:ai training job for busch-lab
.env.example                    # Template for cluster/image configuration
```

## Key conventions

- **Phenotype names**: `advanced`, `intermediate`, `reduced` (secondary growth level).
- XML input files follow the pattern `bean_<phenotype>_p<level>.xml` (e.g., `bean_advanced_p0.17.xml`).
- `Identifiers.txt` lists all 39 filenames, one per line — used by `run-all-sims.sh`.
- Simulation output lands in `$OUTPUT_PATH/<basename>/` where basename strips the `.xml` extension.

## Build & run

```bash
# Build the image
docker build -t osr-bean-p .

# Run a single simulation locally
docker run --rm \
  -e INPUT_FILE=bean_advanced_p1.00.xml \
  -v ./output:/sim/output \
  osr-bean-p

# Run all 39 simulations inside one container
docker run --rm \
  -e GITHUB_TOKEN="$GITHUB_TOKEN" \
  -v ./output:/sim/output \
  osr-bean-p bash /usr/local/bin/run-all-sims.sh

# Submit to Run:ai
cp .env.example .env   # edit as needed
bash scripts/submit-single-job-runai.sh
```

## Development notes

- OpenSimRoot compiles with `make release` under `OpenSimRoot/StaticBuild/` (C++14, g++).
- The Dockerfile uses a multi-stage build to keep the runtime image small.
- `entrypoint.sh` searches both mounted `/sim/input` and bundled `/opt/inputs` for XML configs.
- Set `DRY_RUN=true` in `.env` to preview Run:ai commands without submitting.
- The intermediate phenotype is created from the advanced template with multiplier set to 0.5.
