#!/bin/bash
#$ -cwd
#$ -pe smp 8
#$ -l mem_free=16G
#$ -R y

# Load necessary modules
module load CBI miniconda3/23.5.2-0-py311

# Define paths dont change
DORADO_BIN="/wynton/group/lynch/software/dorado-0.8.2-linux-x64/bin/dorado"  
NANOPLOT_SCRIPT="/wynton/group/lynch/software/NanoPlot-1.42.0/nanoplot/NanoPlot.py"  # Path to NanoPlot.py

# Edit to run specifics Define input and output files
INPUT_BAM="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/dorado_calls_notrim/merged_run.bam"
SUMMARY_TXT="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/nanoplot/nanoplot_summary.txt"
NANOPLOT_OUT="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/nanoplot"

mkdir -p "$NANOPLOT_OUT"

# Run Dorado
echo "Running Dorado summary..."
$DORADO_BIN summary "$INPUT_BAM" > "$SUMMARY_TXT"

# Check if summary file was created
if [[ ! -f "$SUMMARY_TXT" ]]; then
    echo "Error: Dorado summary failed to generate!"
    exit 1
fi

# Run NanoPlot from Python script
echo "Running NanoPlot..."
python3 "$NANOPLOT_SCRIPT" -t 8 -o "$NANOPLOT_OUT" --summary "$SUMMARY_TXT"

echo "NanoPlot completed successfully."

