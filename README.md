# kicadReleaseCI
This repository contain CI job exporting all project outputs from kicad design files using Kicad CLI

## Building new image 

`docker build -t kicad-autogen:latest .`

## Running the container
`docker run --rm -it -v "$(pwd)":/project -w /project kicad-autogen:latest`

## Running with entrypoint set to bash:
`docker run --rm -it \
  --entrypoint bash \
  -v "$(pwd)":/project \
  -w /project \
  kicad-autogen:latest`
