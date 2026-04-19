#!/bin/bash
#$ -cwd
#$ -pe smp 4
#$ -l mem_free=8G
#$ -l h_rt=4:00:00
#$ -R y
#$ -N minibar_run

# Load Apptainer module
module load CBI miniconda3/23.5.2-0-py311
# Define paths
SIF_PATH="/wynton/group/lynch/software/minibar_v1.sif"
SCRIPT_PATH="/wynton/group/lynch/software/Zymo_minibar/minibar.py"
INPUT_FASTQ="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/concatenated.fastq"
OUTPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/minibar_output"
BARCODES="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/Barcodes_Isolates_v1.txt"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Run Minibar to demultiplex
base=$(basename "$INPUT_FASTQ" .fastq)
echo "[$(date)] Running minibar on $base..."

apptainer exec \
  --bind "$(dirname "$INPUT_FASTQ")":"$(dirname "$INPUT_FASTQ")" \
  --bind "$OUTPUT_DIR":"$OUTPUT_DIR" \
  --bind "$(dirname "$SCRIPT_PATH")":"$(dirname "$SCRIPT_PATH")" \
  --pwd "$OUTPUT_DIR" \
  "$SIF_PATH" \
  python3 "$SCRIPT_PATH" "$BARCODES" "$INPUT_FASTQ" -e 1 -E 5 -M 2 -T -F

echo "[$(date)] Minibar complete for $base"

