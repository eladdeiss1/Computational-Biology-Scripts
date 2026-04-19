#!/bin/bash
#$ -N demultiplex_run3
#$ -cwd
#$ -j yes
#$ -pe smp 8            ## request 8 CPU cores
#$ -l h_rt=3:00:00
#$ -l mem_free=6G
#$ -m bea

module load CBI
module load miniforge3/24.11.2-1
conda activate /wynton/group/lynch/software/metaphlan4.2.2 #samtools is in the metaphlan env


echo "QUEUE: $QUEUE"
echo "SGE_GPU: $SGE_GPU"

# GPU visibility
if [[ -z "$SGE_GPU" ]]; then
  export CUDA_VISIBLE_DEVICES=0
else
  export CUDA_VISIBLE_DEVICES=$SGE_GPU
fi

echo "Job started: $(date --rfc-3339=seconds)"

# === Paths ===
DORADO_BIN="/wynton/group/lynch/software/dorado-1.3.0-linux-x64/bin"
BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/"
BAM_DIR="${BASE_DIR}/bam_files"
DEMUX_DIR="${BASE_DIR}/demux"
MERGED_BAM="$BASE_DIR/merged_all.bam"
KIT_NAME="SQK-NBD114-96"
SAMPLE_SHEET="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/samplesheet.csv"
# Ensure necessary directories exist
echo "Ensuring output directories exist..."
mkdir -p "$DEMUX_DIR"

# SECTION 1: Merge all BAM files
# Check if merged BAM already exists
if [ -f "$MERGED_BAM" ]; then
    echo "Merged BAM already exists, skipping merge step."
    echo "Using existing: $(du -h $MERGED_BAM)"
else
    echo "Merging BAM files..."
    samtools merge -@ 8 -c -p "$MERGED_BAM" "$BAM_DIR"/*.bam
    
    if [ ! -f "$MERGED_BAM" ]; then
        echo "ERROR: Merge failed"
        exit 1
    fi
    
    echo "Merge completed. Size: $(du -h $MERGED_BAM)"
fi 
# SECTION 2: Dorado Demultiplexing
echo "Running Dorado demultiplexer..."
"$DORADO_BIN"/dorado demux \
    --output-dir "$DEMUX_DIR" \
    --emit-fastq \
    --sample-sheet "$SAMPLE_SHEET" \
    --kit-name "$KIT_NAME" \
    "$MERGED_BAM"

echo "Demultiplexing completed."

# Print the end timestamp
t1=$(date --rfc-3339=seconds)
echo "Job ended at: $t1"
