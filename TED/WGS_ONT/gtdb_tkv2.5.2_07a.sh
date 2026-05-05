#!/bin/bash
#$ -N gtdbtk_classify
#$ -cwd
#$ -j y
#$ -t 1-17
#$ -tc 4
#$ -pe smp 8
#$ -l mem_free=32G,h_vmem=32G
#$ -l scratch=100G
#$ -l h_rt=8:00:00

set -u

# ---- MODULES ----
module load CBI miniforge3/24.11.2-1
conda activate /wynton/group/lynch/software/gtdbtk-2.5.2

export GTDBTK_DATA_PATH="/wynton/group/lynch/databases/GTDBtk_r226/release226"

# ---- DETERMINE BARCODE ----
TASK_ID=${SGE_TASK_ID:-1}
BARCODE=$(printf "barcode%02d" "${TASK_ID}")

echo "Processing ${BARCODE}"

# ---- PATHS ----
ROOT="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files"

# Medaka-polished assembly (.fasta — handled by cp rename below)
ASSEMBLY="${ROOT}/medaka_subsampled/${BARCODE}/consensus.fasta"

GTDBTK_OUTPUT_DIR="${ROOT}/GTDB_taxa_classification_subsampled/${BARCODE}"

# ---- SANITY CHECK ----
if [[ ! -f "$ASSEMBLY" ]]; then
    echo "ERROR: Polished assembly not found: ${ASSEMBLY}"
    echo "Has Medaka finished for ${BARCODE}?"
    exit 1
fi

# ---- SCRATCH WORKING DIRS ----
TMP_JOB_DIR="${TMPDIR}/${BARCODE}_gtdbtk"
TMP_GENOMES="${TMP_JOB_DIR}/genomes"
TMP_OUT="${TMP_JOB_DIR}/output"

mkdir -p "$TMP_GENOMES" "$TMP_OUT" "$GTDBTK_OUTPUT_DIR"

# Copy and rename .fasta → .fa for GTDB-Tk (no samtools needed)
cp "$ASSEMBLY" "${TMP_GENOMES}/${BARCODE}.fa"

echo "====================================="
echo "Job started at:  $(date)"
echo "Barcode:         ${BARCODE}"
echo "Assembly:        ${ASSEMBLY}"
echo "Output dir:      ${GTDBTK_OUTPUT_DIR}"
echo "====================================="

# ---- RUN GTDB-TK ----
gtdbtk classify_wf \
    --genome_dir "$TMP_GENOMES" \
    --out_dir "$TMP_OUT" \
    --cpus 8 \
    --extension fa \
    --skip_ani_screen

# ---- MOVE RESULTS ----
mv "$TMP_OUT"/* "$GTDBTK_OUTPUT_DIR"

echo "Completed GTDB-Tk for ${BARCODE}"
echo "Results in: ${GTDBTK_OUTPUT_DIR}"
