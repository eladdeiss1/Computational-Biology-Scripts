#!/bin/bash
set -euo pipefail

# --- Environment setup ---
module load CBI
module load miniforge3/24.11.2-1
conda activate 16s-cons
# module load seqtk   # if seqtk isn’t in your conda env, load it here
# -------------------------

SAMPLES_FILE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/samples.txt"
IN_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/fastplong"
OUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/fastplong/fasta"
mkdir -p "$OUT_DIR"

while read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue
    echo "Converting $SAMPLE ..."
    seqtk seq -A "${IN_DIR}/sample_${SAMPLE}_processed.fastq" > "${OUT_DIR}/sample_${SAMPLE}_processed.fa"
done < "$SAMPLES_FILE"

