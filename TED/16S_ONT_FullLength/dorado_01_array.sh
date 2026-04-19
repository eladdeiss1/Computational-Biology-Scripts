#!/bin/bash
#$ -N dorado-adaptive        # Job name
#$ -cwd                      # Use current working directory
#$ -j yes                    # Merge stdout and stderr
#$ -q gpu.q                  # Specify GPU queue
#$ -l h_rt=12:00:00
#$ -l mem_free=16G
#$ -t 1-20

# Print queue and GPU info
echo "QUEUE: $QUEUE"
echo "SGE_GPU: $SGE_GPU"

# Set CUDA visibility
if [[ -z "$SGE_GPU" ]]; then
  export CUDA_VISIBLE_DEVICES=0
else
  export CUDA_VISIBLE_DEVICES=$SGE_GPU
fi

# Start time
echo "Job started at: $(date --rfc-3339=seconds)"

# Variables
DORADO_BIN="/wynton/group/lynch/software/dorado-1.0.2-linux-x64/bin"
BASECALL_MODEL="dna_r10.4.1_e8.2_400bps_sup@v5.2.0"
#KIT_NAME="SQK-NBD114-24"
POD5_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/pod5"
#SAMPLE_SHEET="/wynton/group/lynch/eladdy/LongRead_CANOE_Airway/Pilot_v2_AdaptiveSampling_May2025/Sample_Sheet_Pilot_v1.csv"
OUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/dorado_calls_notrim"
# Ensure output directory exists
mkdir -p "$OUT_DIR"

# Construct filename based on array index (zero-padded to 3 digits)
ID=$((SGE_TASK_ID-1))
POD5_FILE="${POD5_DIR}/FBD97507_78286852_cc2b03d4_${ID}.pod5"
OUTPUT_FILE="${OUT_DIR}/FBD97507_78286852_cc2b03d4${ID}_calls.bam"

# Check that the file exists
if [[ ! -f "$POD5_FILE" ]]; then
  echo "Error: POD5 file not found: $POD5_FILE"
  exit 1
fi

# Run Dorado
cd "$DORADO_BIN"
./dorado basecaller "$BASECALL_MODEL" "$POD5_FILE" \
  --no-trim \
  > "$OUTPUT_FILE"

# End time
echo "Finished task $SGE_TASK_ID at: $(date --rfc-3339=seconds)"

