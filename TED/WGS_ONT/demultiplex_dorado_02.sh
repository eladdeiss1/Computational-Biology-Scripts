#!/bin/bash

# Job settings for the cluster
#$ -N dorado-pipeline-job  ## job name
#$ -cwd                    ## use current working directory
#$ -j yes                  ## merge stdout and stderr
#$ -q gpu.q                ## specify the GPU queue
#$ -pe smp 8               ## request 8 CPU cores
#$ -l mem_free=16G         ## request 16GB memory
#$ -l h_rt=09:00:00        ## runtime limit: 9 hours

# Print information about the queue and GPU assignment
echo "QUEUE: $QUEUE"
echo "SGE_GPU: $SGE_GPU"

# Set CUDA_VISIBLE_DEVICES to control GPU visibility
#export CUDA_VISIBLE_DEVICES=$SGE_GPU

# Print the start timestamp
t0=$(date --rfc-3339=seconds)
echo "Job started at: $t0"

# Define paths
DORADO_BIN="/wynton/group/lynch/software/dorado-0.8.2-linux-x64/bin"
SAMPLE_SHEET="/wynton/group/lynch/mbacino/25_01_09_OHPERIO_AS_pilot/input_files/25_01_07_ss.csv"
CALLS_BAM="/wynton/group/lynch/mbacino/25_01_09_OHPERIO_AS_pilot/output_files/25_02_04_calls.bam"
DEMUX_DIR="/wynton/group/lynch/mbacino/25_01_09_OHPERIO_AS_pilot/output_files/demux_fastq"

# Ensure necessary directories exist
echo "Ensuring output directories exist..."
#mkdir -p "$(dirname "$CALLS_BAM")"
mkdir -p "$DEMUX_DIR"


# SECTION 2: Dorado Demultiplexing
echo "Running Dorado demultiplexer..."
"$DORADO_BIN"/dorado demux --output-dir "$DEMUX_DIR" --no-classify --emit-fastq "$CALLS_BAM"
echo "Demultiplexing completed."


# Print the end timestamp
t1=$(date --rfc-3339=seconds)
echo "Job ended at: $t1"
