#!/usr/bin/env bash
set +e

########################################
# CONFIG
########################################
# Where we put all generated output, relative to /project
OUTPUT_ROOT="/project/outputs"

# You can modify which layers get included in the board PDF
BOARD_PDF_LAYERS="F.Cu,B.Cu,F.SilkS,B.SilkS,Edge.Cuts"

########################################
# PREP
########################################
# Make sure the output directory exists
mkdir -p "${OUTPUT_ROOT}"

# Move into /project so our find paths are relative to "."
cd /project

echo "Searching for .kicad_pcb files in $(pwd)..."
mapfile -t PCB_FILES < <(find . -type f -name '*.kicad_pcb')

if [ ${#PCB_FILES[@]} -eq 0 ]; then
  echo "No .kicad_pcb files found. Exiting."
  exit 0
fi

########################################
# PROCESS EACH PCB
########################################
for pcb_file in "${PCB_FILES[@]}"; do
  echo
  echo "Found PCB: $pcb_file"

  # Derive the 'relative' folder path of the PCB file
  # e.g., if pcb_file = ./sub/folder/myboard.kicad_pcb
  #       then pcb_dir = ./sub/folder
  pcb_dir="$(dirname "$pcb_file")"

  # Base name of the PCB file (without .kicad_pcb)
  # e.g., myboard
  base_name="$(basename "$pcb_file" .kicad_pcb)"

  # Where we will store outputs (e.g. /project/outputs/sub/folder)
  # We'll replicate the original sub-path under OUTPUT_ROOT
  # "realpath --relative-to" ensures we keep the relative path from the root
  relative_dir="$(realpath --relative-to=. "$pcb_dir")"
  target_dir="${OUTPUT_ROOT}/${relative_dir}"

  # Create that structure
  mkdir -p "${target_dir}"
  mkdir -p "${target_dir}/schematic"
  mkdir -p "${target_dir}/board"
  mkdir -p "${target_dir}/fabrication"

  # Check if there's a matching schematic
  sch_file="${pcb_dir}/${base_name}.kicad_sch"
  if [ -f "${sch_file}" ]; then
    echo "  - Matching schematic found: ${sch_file}"
    echo "    -> Exporting schematic PDF..."
    kicad-cli sch export pdf "${sch_file}" \
      --output "${target_dir}/schematic/${base_name}_schematic.pdf"
      
    echo "    -> Exporting schematic SVG..."
    kicad-cli sch export svg "${sch_file}" \
      --output "${target_dir}/schematic/${base_name}_schematic_SVG"
      
    echo "    -> Generating ERC report..."
    kicad-cli sch erc "${sch_file}" \
      --output "${target_dir}/schematic/${base_name}_schematic.rpt"

    echo "    -> Exporting BOM (CSV)..."
    kicad-cli sch export bom "${sch_file}" \
--output "${target_dir}/fabrication/${base_name}_bom.csv" --fields Reference,Value,Footprint,Qty,Manufacturer,MPN,Datasheet --group-by Value
  else
    echo "  - No matching schematic found, skipping schematic PDF and BOM."
  fi

  # Export board PDF
  echo "  -> Exporting board PDF..."
  kicad-cli pcb export pdf "${pcb_file}" \
    --output "${target_dir}/${base_name}_board.pdf" \
    --layers "${BOARD_PDF_LAYERS}"

  # Generate Gerbers
  echo "  -> Generating Gerbers..."
  kicad-cli pcb export gerbers "${pcb_file}" \
    --output "${target_dir}"

  # Generate NC drill files
  echo "  -> Generating NC drill files..."
  kicad-cli pcb export drill "${pcb_file}" \
    --output "${target_dir}"

  echo "  -> All outputs saved to: ${target_dir}"
done

echo
echo "Done! All PCB outputs are under ${OUTPUT_ROOT}."
