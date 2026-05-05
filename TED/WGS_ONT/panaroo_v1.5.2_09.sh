#!/bin/bash
#$ -N Mcat_panaroo
#$ -cwd
#$ -pe smp 8
#$ -l mem_free=8G
#$ -l h_rt=24:00:00 #enough time for 50 HQ MAGs

set -euo pipefail

PANAROO="/wynton/group/lynch/software/panaroo_v1.5.2.sif"

# ====== MUST MATCH YOUR SPECIES ======
SPECIES_NAME="Moraxella_catarrhalis"

# ======================================

BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/"
ANNOTATION_DIR="${BASE_DIR}/bakta_annotations_${SPECIES_NAME}"
PANGENOME_DIR="${BASE_DIR}/pangenome_${SPECIES_NAME}"
OUTPUT_DIR="${PANGENOME_DIR}/panaroo_output"

# Create parent directory
mkdir -p "$PANGENOME_DIR"

# Verify it was created
if [[ ! -d "$PANGENOME_DIR" ]]; then
    echo "ERROR: Failed to create $PANGENOME_DIR"
    exit 1
fi

echo "Pangenome directory exists: $PANGENOME_DIR"

# Remove output directory if it exists
[[ -d "$OUTPUT_DIR" ]] && rm -rf "$OUTPUT_DIR"

echo "========================================"
echo "Step 1: Finding GFF3 files for ${SPECIES_NAME}"
echo "========================================"

find "$ANNOTATION_DIR" -type f -name "*.gff3" > "${PANGENOME_DIR}/gff_list.txt"

GFF_COUNT=$(wc -l < "${PANGENOME_DIR}/gff_list.txt")
echo "Found $GFF_COUNT GFF3 files"

if [[ $GFF_COUNT -eq 0 ]]; then
    echo "ERROR: No GFF3 files found"
    exit 1
fi

cat "${PANGENOME_DIR}/gff_list.txt"

echo ""
echo "========================================"
echo "Step 2: Running Panaroo"
echo "========================================"

# Add explicit bind mounts for Apptainer
apptainer exec \
    --bind /wynton/group/lynch \
    ${PANAROO} panaroo \
    -i "${PANGENOME_DIR}/gff_list.txt" \
    -o "$OUTPUT_DIR" \
    --clean-mode strict \
    --remove-invalid-genes \
    -t 8 \
    --alignment core \
    -a pan \
    --aligner mafft 

echo ""
echo "========================================"
echo "Panaroo complete!"
echo "========================================"
