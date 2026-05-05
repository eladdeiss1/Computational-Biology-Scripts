#!/bin/bash
#$ -cwd
#$ -N CheckM2_barcodes
#$ -pe smp 4
#$ -l mem_free=8G,h_vmem=8G
#$ -l h_rt=24:00:00
#$ -l scratch=50G
#$ -R y
#$ -j y


# -------------------------------------------------------------------
# Load environment
# -------------------------------------------------------------------
module load CBI
module load miniforge3/24.11.2-1

THREADS=${NSLOTS:-4}

BASE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files"
GENOME_DIR="${BASE}/gtdb_genomes"

CHECKM2_DB_DIR="/wynton/group/lynch/databases/checkm2_db"
CHECKM2_DB="/checkM2_db/CheckM2_database/uniref100.KO.1.dmnd"

CHECKM2_SIF="/wynton/group/lynch/software/checkm2.sif"

echo "[INFO] Starting CheckM2 batch run with ${THREADS} threads"
echo "[INFO] Genome directory: $GENOME_DIR"
echo "[INFO] Output base directory: $BASE/checkM2"

mkdir -p "$BASE/checkM2"

# ===================================================================
# Loop through barcode01 to barcode17
# ===================================================================

for i in {01..17}; do
    SAMPLE="barcode${i}"
    INPUT="${GENOME_DIR}/${SAMPLE}_assembly.fa"
    OUTDIR="$BASE/checkM2/${SAMPLE}"

    echo "-----------------------------------------------------------"
    echo "[INFO] Processing $SAMPLE"
    echo "-----------------------------------------------------------"

    # Skip missing barcode16 or others gracefully
    if [[ ! -f "$INPUT" ]]; then
        echo "[WARNING] Missing input file: $INPUT"
        echo "[WARNING] Skipping ${SAMPLE}"
        continue
    fi

    mkdir -p "$OUTDIR/checkm2_out"

    # ----------------------------------------------------------------
    # Run CheckM2
    # ----------------------------------------------------------------
    echo "[INFO] Running CheckM2 on $SAMPLE"

    apptainer exec \
      --bind "$GENOME_DIR":/input_genomes \
      --bind "$CHECKM2_DB_DIR":/checkM2_db \
      --bind "$OUTDIR":/checkM2 \
      "$CHECKM2_SIF" \
      checkm2 predict \
          --threads "$THREADS" \
          --input "/input_genomes/${SAMPLE}_assembly.fa" \
          --database_path "$CHECKM2_DB" \
          --output_dir "/checkM2/checkm2_out" \
          --force

    echo "[INFO] Finished CheckM2 for ${SAMPLE}"
done

echo "[INFO] All barcodes processed."
echo "[INFO] Finished at: $(date)"

