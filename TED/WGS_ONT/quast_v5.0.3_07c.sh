#!/bin/bash
#$ -cwd
#$ -N Quast_25_12_10
#$ -pe smp 8
#$ -l mem_free=8G
#$ -l scratch=50G
#$ -l h_rt=4:00:00
#$ -R y
#$ -m bea
#$ -t 1-17

# --- Constants / tools ---
QUAST_SIF="/wynton/group/lynch/software/quast5.0.3.sif"

BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f"
QUAST_OUTPUT_BASE="${BASE_DIR}/output_files/quast_output"
cd "$BASE_DIR" 

# Input list
SAMPLES_FILE="samples.txt"
[[ -s "$SAMPLES_FILE" ]] || { echo "[ERROR] $SAMPLES_FILE not found/empty"; exit 1; }

# Guard for direct runs
: "${SGE_TASK_ID:=1}"

# Derive barcode
BARCODE=$(sed -n "${SGE_TASK_ID}p" "$SAMPLES_FILE" | tr -d '[:space:]')
[[ -n "$BARCODE" ]] || { echo "[ERROR] No barcode at line $SGE_TASK_ID"; exit 1; }
echo "Processing barcode: $BARCODE"

# Define paths
INPUT_DIR="${BASE_DIR}/output_files/autocycler/${BARCODE}/autocycler_out"
OUTPUT_DIR="${QUAST_OUTPUT_BASE}/${BARCODE}"
ASSEMBLY="${INPUT_DIR}/consensus_assembly.fasta"

echo "Input directory:  $INPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Assembly file: $ASSEMBLY"

# Basic checks
[[ -d "$INPUT_DIR" ]] || { echo "[ERROR] Input dir does not exist: $INPUT_DIR"; exit 1; }
[[ -f "$ASSEMBLY" ]]   || { echo "[ERROR] consensus_assembly.fasta not found for $BARCODE"; exit 1; }

mkdir -p "$OUTPUT_DIR"

# Scratch/TMPDIR
TMPDIR="/scratch/$USER/$JOB_ID/$SGE_TASK_ID"
mkdir -p "$TMPDIR"
export TMPDIR

# Use allocated cores
THREADS="${NSLOTS:-8}"

# Run QUAST via Apptainer
apptainer exec \
  -B /wynton/group/lynch:/wynton/group/lynch \
  -B "$TMPDIR":"$TMPDIR" \
  "$QUAST_SIF" \
  quast.py \
    --threads "$THREADS" \
    --output-dir "$OUTPUT_DIR" \
    --min-contig 500 \
    --labels "${BARCODE}" \
    "$ASSEMBLY"

echo "Done: $BARCODE - Results in $OUTPUT_DIR"
