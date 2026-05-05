#!/bin/bash
#$ -N medaka_barcode21
#$ -cwd
#$ -j y
#$ -pe smp 8
#$ -l mem_free=16G,h_vmem=16G
#$ -l h_rt=8:00:00

# ---- PATHS ----
READS="/wynton/group/lynch/eladdy/Din_LongRead/barcode21/combined_barcode21_processed.fastq"
ASSEMBLY="/wynton/group/lynch/eladdy/Din_LongRead/barcode21/barcode21_50xCoverage/autocycler/assemblies/flye_01.fasta"
OUT_DIR="/wynton/group/lynch/eladdy/Din_LongRead/barcode21/barcode21_50xCoverage/medaka"
MEDAKA_MODEL="r1041_e82_400bps_sup_v5.2.0"
THREADS=${NSLOTS:-8}

# ---- SETUP ----
mkdir -p "${OUT_DIR}"

module load CBI
module load miniforge3
conda activate /wynton/group/lynch/software/medaka_env

echo "====================================="
echo "Job started at: $(date)"
echo "Reads:          ${READS}"
echo "Assembly:       ${ASSEMBLY}"
echo "Output dir:     ${OUT_DIR}"
echo "Model:          ${MEDAKA_MODEL}"
echo "Threads:        ${THREADS}"
echo "====================================="

# ---- SANITY CHECKS ----
if [[ ! -f "${READS}" ]]; then
    echo "ERROR: Reads file not found: ${READS}"
    exit 1
fi

if [[ ! -f "${ASSEMBLY}" ]]; then
    echo "ERROR: Assembly file not found: ${ASSEMBLY}"
    exit 1
fi

# ---- RUN MEDAKA ----
echo "[$(date)] Running Medaka polishing..."

medaka_consensus \
    -i "${READS}" \
    -d "${ASSEMBLY}" \
    -o "${OUT_DIR}" \
    -m "${MEDAKA_MODEL}" \
    -t "${THREADS}"

if [[ $? -ne 0 ]]; then
    echo "ERROR: Medaka failed"
    exit 1
fi

echo "[$(date)] Medaka polishing complete!"
echo "Polished assembly: ${OUT_DIR}/consensus.fasta"
