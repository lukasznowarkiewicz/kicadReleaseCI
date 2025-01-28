# KiCad Release CI

This repository provides:

1. A **Docker-based** environment for running [KiCad 8.x](https://www.kicad.org/) in a CI context.  
2. A **reusable GitHub Actions workflow** (`.github/workflows/kicad_export.yml`) that you can call from your PCB project repos.  
3. A **script** that automatically searches for `.kicad_pcb` (and matching `.kicad_sch`) files, exports manufacturing outputs, and stores them in an `outputs/` folder.

## Table of Contents

- [Intended Use](#intended-use)  
- [Using From Another Repository](#using-from-another-repository)  
- [Development](#development)  
  - [1. Build Docker Image Locally](#1-build-docker-image-locally)  
  - [2. Run the Docker Container](#2-run-the-docker-container)  
  - [3. Modify the Export Script](#3-modify-the-export-script)  
- [What is Exported](#what-is-exported)  
- [License](#license)  

---

## Intended Use

- **Automate** KiCad manufacturing outputs (Gerbers, Drill files, BOM, PDF plots, etc.) for your hardware projects.  
- Keep the CI logic and Docker environment **centralized**.  
- **Reusable** across multiple PCB projects.  
- Fully **headless** KiCad environment, leveraging `kicad-cli` commands in KiCad 8.

---

## Using From Another Repository

### 1) Reference Our Reusable Workflow

In your **KiCad project repository**, create a workflow file (e.g., `.github/workflows/kicad_export_caller.yml`):

```yaml
name: "Kicad 8 release CI"

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  # or to allow manual triggers:
  # workflow_dispatch:

jobs:
  call-export:
    uses: lukasznowarkiewicz/kicadReleaseCI/.github/workflows/kicad_export.yml@main
    with:
      target_repo: ${{ github.repository }}
      target_ref: ${{ github.ref }}
```

- **`uses:`** points to this repo’s workflow file (`kicad_export.yml`).  
- **`target_repo`** and **`target_ref`** are inputs required by the reusable workflow to know which repo and branch to check out.

### 2) Trigger the Workflow

- Whenever you push to `main` or open a pull request, GitHub Actions calls `kicad_export.yml` from **kicadReleaseCI**, checks out your KiCad files, and runs the export container.  
- The results are uploaded as an artifact named `kicad-outputs`. Download it from the “Actions” tab in your project repo.

> **Note**: If your `kicadReleaseCI` repo is **private**, ensure you have set the right permissions and that both repos are in the same organization (or you have a proper token setup).

---

## Development

If you want to **develop** or **modify** this CI workflow in `kicadReleaseCI`, here are common tasks:

### 1. Build Docker Image Locally

```bash
git clone https://github.com/lukasznowarkiewicz/kicadReleaseCI.git
cd kicadReleaseCI
docker build -t kicad-autogen:latest .
```

This uses the local `Dockerfile`, which installs KiCad 8 and copies the `generate_kicad_outputs.sh` script.

### 2. Run the Docker Container

You can run the image manually, mounting a **KiCad project** folder to `/project`:

```bash
docker run --rm -it -v "$(pwd)":/project -w /project kicad-autogen:latest
```

or optinally run container and enter containers' bash:
```bash
docker run --rm -it \
  --entrypoint bash \
  -v "$(pwd)":/project \
  -w /project \
  kicad-autogen:latest
```

- The container entrypoint calls `generate_kicad_outputs.sh`, which searches `/project` for `.kicad_pcb` files, exports all outputs, and places them into `outputs/` subfolders.
- When the container finishes, check `some_kicad_project/outputs/` on your host system for the results.

### 3. Modify the Export Script

- The **main logic** is in `generate_kicad_outputs.sh`. It does:
  - `find . -type f -name '*.kicad_pcb'` to locate boards in subfolders.
  - If a matching `.kicad_sch` is found, exports schematic PDF & BOM.
  - Exports board PDF, Gerbers, and NC drill files for each PCB.
  - Places everything under a mirrored folder structure in `outputs/<subdirectory>`.
- **Common tweaks**:
  - Change PDF layers (default is `F.Cu,B.Cu,F.SilkS,B.SilkS,Edge.Cuts`).
  - Add or remove exports (e.g. `kicad-cli pcb export svg`).
  - Add optional 3D or advanced BOM scripts.

After changes, **rebuild** the Docker image or push to GitHub so the updated script is used in subsequent CI runs.

---

## What is Exported

By default, the script exports the following for each `.kicad_pcb`:

1. **Board PDF**: A multi-layer PDF of copper layers, silkscreen, and board edges.  
2. **Gerber Files**: For each layer, plus `.gbrjob`.  
3. **NC Drill Files**: Excellon drills (`.drl`, `.map`).  
4. **Schematic PDF & BOM**: If a **matching** `.kicad_sch` (same base name) is found. BOM is exported as `.csv`.

All generated files go into `outputs/<mirroring the original folder structure>`. For instance, if your KiCad board is at `sub/folder/myboard.kicad_pcb`, the outputs go to `outputs/sub/folder/`.

---

## License

This project is published under the [Apache-2.0](LICENSE) license.
