#!/bin/bash
#$ -cwd
#$ -pe smp 4
#$ -l mem_free=16G
#$ -R y

# Define input and output directories
INPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/demux"
OUTPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/fastplong"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run FastpLong on each .fastq file in INPUT_DIR
for INPUT_FILE in "$INPUT_DIR"/*.fastq; do
    if [[ -f "$INPUT_FILE" ]]; then
        # Extract the barcode number (e.g., barcode09, barcode10)
        BARCODE=$(echo "$INPUT_FILE" | grep -o "barcode[0-9]\+")

        # Extract the base filename without the directory and extension
        BASENAME=$(basename "$INPUT_FILE" .fastq)
        
        # Define output file paths
        FASTPLONG_OUTPUT="${OUTPUT_DIR}/${BARCODE}_processed.fastq"
        FASTPLONG_HTML="${OUTPUT_DIR}/${BARCODE}_fastp_report.html"

        echo "Running FastpLong on $INPUT_FILE..."
        
        # Run FastpLong
        /wynton/group/lynch/software/fastplong.0.2.2 --in "$INPUT_FILE" \
            --out "$FASTPLONG_OUTPUT" \
            -A \
            -l 250 \
            -q 20 \
            --html "$FASTPLONG_HTML"

        echo "Completed processing $INPUT_FILE"
    else
        echo "No FASTQ files found in $INPUT_DIR"
    fi
done

echo "All FastpLong processing completed."

