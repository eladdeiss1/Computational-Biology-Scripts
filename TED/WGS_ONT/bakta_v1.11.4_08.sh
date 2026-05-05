#!/bin/bash
#$ -N bakta_M_cat
#$ -cwd
#$ -pe smp 8
#$ -l mem_free=8G
#$ -l scratch=50G
#$ -l h_rt=16:00:00

set -euo pipefail

module load CBI miniforge3/24.11.2-1
conda activate /wynton/group/lynch/software/bakta

# ====== MUST MATCH SPECIES ======
SPECIES_NAME="Moraxella_catarrhalis"
# ================================

BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files"
ANNOTATION_BASE="${BASE_DIR}/bakta_annotations_${SPECIES_NAME}"
BAKTA_DB="/wynton/group/lynch/databases/bakta_db_v6/db"
SAMPLES_FILE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/samples_bakta.txt"

mkdir -p "$ANNOTATION_BASE"

echo "========================================"
echo "Annotating ${SPECIES_NAME} genomes"
echo "========================================"

while read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue   # skip empty lines

    bin_file="${BASE_DIR}/gtdb_genomes/${SAMPLE}_assembly.fa"

    if [[ ! -f "$bin_file" ]]; then
        echo "[WARNING] Missing assembly for ${SAMPLE}: $bin_file"
        continue
    fi

    safe_bin_name=$(echo "$SAMPLE" | sed 's/[^A-Za-z0-9_-]/_/g')
    output_dir="${ANNOTATION_BASE}/${safe_bin_name}"

    if [[ -f "${output_dir}/${safe_bin_name}.gff3" ]]; then
        echo "Skipping ${SAMPLE} - already annotated"
        continue
    fi

    rm -rf "$output_dir"
    mkdir -p "$output_dir"

    echo "Annotating ${SAMPLE}..."

    bakta \
        --db "$BAKTA_DB" \
        --output "$output_dir" \
        --prefix "$safe_bin_name" \
        --threads 8 \
	--force \
        "$bin_file"

    echo "Done: ${SAMPLE}"

done < "$SAMPLES_FILE"

echo "========================================"
echo "All annotations complete!"
echo "========================================"
