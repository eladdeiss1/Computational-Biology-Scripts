#!/bin/bash
#$ -N rasusa_downsample
#$ -cwd
#$ -j y
#$ -pe smp 1
#$ -l mem_free=8G
#$ -l h_rt=02:00:00


module load CBI miniforge3
conda activate /wynton/group/lynch/software/rasusa

# ====== PATHS ======
BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files"
INPUT_DIR="${BASE_DIR}/fastplong"
OUTPUT_DIR="${BASE_DIR}/subsampled"

COVERAGE=100
GENOME_SIZE="2mb"
# ===================

mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "Detecting barcodes in: ${INPUT_DIR}"
echo "========================================"

# Find all barcodeXX_processed.fastq files and extract barcode names
BARCODES=()
for fastq in "${INPUT_DIR}"/barcode*_processed.fastq; do
    if [[ -f "$fastq" ]]; then
        # Extract just the barcodeXX part (strip path and _processed.fastq)
        barcode=$(basename "$fastq" _processed.fastq)
        BARCODES+=("$barcode")
        echo "  Found: $barcode"
    fi
done

if [[ ${#BARCODES[@]} -eq 0 ]]; then
    echo "ERROR: No barcode*_processed.fastq files found in ${INPUT_DIR}"
    exit 1
fi

echo "Found ${#BARCODES[@]} barcodes"

echo ""
echo "========================================"
echo "Subsampling at ${COVERAGE}x (genome size: ${GENOME_SIZE})"
echo "========================================"

for barcode in "${BARCODES[@]}"; do
    INPUT_FASTQ="${INPUT_DIR}/${barcode}_processed.fastq"
    BARCODE_OUT_DIR="${OUTPUT_DIR}/${barcode}"

    mkdir -p "$BARCODE_OUT_DIR"

    echo ""
    echo "Processing: ${barcode}"
    echo "  Input:  ${INPUT_FASTQ}"
    echo "  Output: ${BARCODE_OUT_DIR}/${barcode}_${COVERAGE}x.fastq"

    rasusa reads \
        "$INPUT_FASTQ" \
        --coverage "$COVERAGE" \
        --genome-size "$GENOME_SIZE" \
        --output "${BARCODE_OUT_DIR}/${barcode}_${COVERAGE}x.fastq"

    echo "  Done: ${barcode}"
done

echo ""
echo "========================================"
echo "All barcodes complete: $(date)"
echo "========================================"
