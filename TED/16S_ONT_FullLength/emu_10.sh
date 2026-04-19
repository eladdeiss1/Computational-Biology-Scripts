#!/bin/bash
#$ -cwd
#$ -pe smp 8              # Request 8 threads
#$ -l mem_free=8G
#$ -l h_rt=12:00:00
#$ -N emu_fastp_abundance
#$ -t 2-167                # Array range: 1 header + 166 samples

# Activate your Emu environment
module load CBI
module load miniforge3/24.11.2-1
conda activate /wynton/group/lynch/databases/ehomd_EDY/emu-py310

# Set variables
MANIFEST="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/manifest.tsv"
EMU_DB="/wynton/group/lynch/databases/ehomd_EDY/ehomd_emu_db_EDY"
OUTDIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/emu_output_fastplong"

mkdir -p "$OUTDIR"

# Get the corresponding line for the current task (skip header)
LINE=$(sed -n "${SGE_TASK_ID}p" "$MANIFEST")

# Extract fields
SAMPLE_ID=$(echo "$LINE" | cut -f1)
FASTQ=$(echo "$LINE" | cut -f2)

# Run Emu
emu abundance \
  --db "$EMU_DB" \
  --threads 8 \
  --keep-files \
  --keep-counts \
  --keep-read-assignments \
  --output-dir "${OUTDIR}/${SAMPLE_ID}" \
  "$FASTQ"

mv emu_abundance.* log_files/
