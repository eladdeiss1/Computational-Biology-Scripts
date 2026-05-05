#!/bin/bash
#$ -cwd
#$ -N autocycler_barcodes
#$ -t 1-17
#$ -tc 6
#$ -pe smp 8
#$ -l mem_free=8G,h_vmem=8G
#$ -l h_rt=48:00:00
#$ -j y

# NOTE: no "set -e" or pipefail so that assembler failures (e.g. canu) don't kill the task
set -u

# ---- Modules / Conda environment ----
module load CBI
module load miniforge3
conda activate /wynton/group/lynch/software/autocycler_env

# ---- CONSTANT PATHS / SETTINGS ----
ROOT="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files"
OUTBASE="${ROOT}"
GENOME_SIZE="2.0m"      # ~2 Mb
THREADS=${NSLOTS:-16}
# ------------------------------------

# ---- DETERMINE BARCODE FOR THIS ARRAY TASK ----
TASK_ID=${SGE_TASK_ID:-1}
BARCODE=$(printf "barcode%02d" "${TASK_ID}")   # barcode01, barcode02, ... barcode17
SAMPLE="${BARCODE}"

READS_FASTQ="${ROOT}/subsampled/${BARCODE}/${BARCODE}_100x.fastq"

# Per-sample output and subsample dirs
SAMPLE_OUT="${OUTBASE}/autocycler_subsampled/${SAMPLE}"
SUBSAMP_DIR="${SAMPLE_OUT}/subsampled_reads"

mkdir -p "${SAMPLE_OUT}"
mkdir -p "${SUBSAMP_DIR}"
cd "${SAMPLE_OUT}"

echo "[$(date)] Starting Autocycler for sample: ${SAMPLE}"
echo "Task ID:      ${TASK_ID}"
echo "Barcode:      ${BARCODE}"
echo "Reads FASTQ:  ${READS_FASTQ}"
echo "Output dir:   ${SAMPLE_OUT}"
echo "Threads:      ${THREADS}"
echo "Genome size:  ${GENOME_SIZE}"
echo

# Basic sanity check
if [[ ! -f "${READS_FASTQ}" ]]; then
  echo "[$(date)] ERROR: Subsampled reads file not found: ${READS_FASTQ}"
  echo "Make sure that the rasusa subsampling ran correctly first. Exiting this task."
  exit 1
fi

# ----------------------------------------------------
# 1) Subsample reads for this barcode
# ----------------------------------------------------
echo "[$(date)] Subsampling reads..."
autocycler subsample \
  --reads "${READS_FASTQ}" \
  --out_dir "${SUBSAMP_DIR}" \
  --genome_size "${GENOME_SIZE}"

echo "[$(date)] Subsampling done."
echo

# ----------------------------------------------------
# 2) Assemble with multiple assemblers
#    If any assembler fails (e.g. canu), we log a warning and continue.
# ----------------------------------------------------
mkdir -p assemblies

for assembler in canu flye metamdbg miniasm necat nextdenovo plassembler raven; do
  for i in 01 02 03 04; do
    echo "[$(date)] Assembler: ${assembler}, subset ${i}"
    autocycler helper "${assembler}" \
      --reads "${SUBSAMP_DIR}/sample_${i}.fastq" \
      --out_prefix "assemblies/${assembler}_${i}" \
      --threads "${THREADS}" \
      --genome_size "${GENOME_SIZE}" \
      || echo "[$(date)] WARNING: ${assembler} subset ${i} failed for ${SAMPLE}, continuing."
  done
done

echo "[$(date)] Assembly stage finished for ${SAMPLE} (some assemblers may have failed)."
echo

# optional cleanup of subsampled reads
rm -f "${SUBSAMP_DIR}"/*.fastq || true

# ----------------------------------------------------
# 3) Compress assemblies → graph
# ----------------------------------------------------
echo "[$(date)] Running autocycler compress for ${SAMPLE}..."
autocycler compress \
  -i assemblies \
  -a autocycler_out

echo "[$(date)] compress done."
echo

# ----------------------------------------------------
# 4) Cluster contigs → replicons
# ----------------------------------------------------
echo "[$(date)] Running autocycler cluster for ${SAMPLE}..."
autocycler cluster \
  -a autocycler_out

echo "[$(date)] cluster done."
echo

# ----------------------------------------------------
# 5) Trim + resolve QC-pass clusters
# ----------------------------------------------------
echo "[$(date)] Processing QC-pass clusters (trim + resolve) for ${SAMPLE}..."

if ls autocycler_out/clustering/qc_pass/cluster_* 1> /dev/null 2>&1; then
  for c in autocycler_out/clustering/qc_pass/cluster_*; do
    echo "[$(date)] Cluster: ${c}"

    autocycler trim -c "${c}" \
      || echo "[$(date)] WARNING: trim failed for ${c} (${SAMPLE}), continuing."

    autocycler resolve -c "${c}" \
      || echo "[$(date)] WARNING: resolve failed for ${c} (${SAMPLE}), continuing."
  done
else
  echo "[$(date)] WARNING: No QC-pass clusters found for ${SAMPLE}."
fi

echo "[$(date)] Cluster processing done for ${SAMPLE}."
echo

# ----------------------------------------------------
# 6) Combine → final consensus assembly
# ----------------------------------------------------
echo "[$(date)] Running autocycler combine for ${SAMPLE}..."

autocycler combine \
  -a autocycler_out \
  -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa \
  || echo "[$(date)] WARNING: combine step failed or no 5_final.gfa files found for ${SAMPLE}."

echo
echo "[$(date)] DONE for ${SAMPLE}!"
echo "Final assembly (if successful):"
echo "  ${SAMPLE_OUT}/autocycler_out/consensus_assembly.fasta"

