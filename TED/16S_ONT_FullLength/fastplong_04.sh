#!/bin/bash
#$ -cwd
#$ -pe smp 4
#$ -l mem_free=16G
#$ -R y
#$ -N fastplong_batch

# Define input and output directories
INPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/minibar_output"
OUTPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/fastplong"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run FastpLong on each .fastq file in INPUT_DIR
for INPUT_FILE in "$INPUT_DIR"/*.fastq; do
    if [[ -f "$INPUT_FILE" ]]; then
        # Extract base name like sample_S113
        BARCODE=$(basename "$INPUT_FILE" .fastq)

        # Define output file paths
        FASTPLONG_OUTPUT="${OUTPUT_DIR}/${BARCODE}_processed.fastq"
        FASTPLONG_HTML="${OUTPUT_DIR}/${BARCODE}_fastp_report.html"
        FASTPLONG_JSON="${OUTPUT_DIR}/${BARCODE}_fastp_report.json"

        echo "[$(date)] Running FastpLong on $INPUT_FILE..."
        
        /wynton/group/lynch/software/fastplong.0.2.2 --in "$INPUT_FILE" \
            --out "$FASTPLONG_OUTPUT" \
            -A \
            --length_required 1400 \
            --length_limit 1700 \
	    -q 20 \
            --html "$FASTPLONG_HTML" \
            --json "$FASTPLONG_JSON"

        echo "[$(date)] Completed processing $INPUT_FILE"
    fi
done

echo "All FastpLong processing completed."

