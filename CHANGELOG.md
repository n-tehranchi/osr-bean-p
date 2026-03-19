# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-03-19

### Added

- Multi-stage Dockerfile that compiles OpenSimRoot from source on Ubuntu 22.04 (`make release`, C++14/g++)
- `scripts/generate_inputs.py` — generates 39 XML input files (3 phenotypes × 13 P levels) from two Strock et al. (2018) template XMLs
- 39 XML input files covering advanced, intermediate, and reduced secondary growth across 13 soil phosphorus concentrations (0.17–5.0 kg/ha)
- `scripts/entrypoint.sh` — container entrypoint that reads `INPUT_FILE` env var and runs the simulator
- `scripts/run-all-sims.sh` — loops through all 39 files from `Identifiers.txt`, runs each simulation, and pushes results to GitHub
- `scripts/submit-single-job-runai.sh` — submits one Run:ai training job for the `busch-lab` project
- `.env.example` with configuration template for cluster settings
- Project documentation: README, QUICKSTART, CLAUDE.md, CHANGELOG
