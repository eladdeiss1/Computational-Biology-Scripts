#!/bin/bash
#$ -cwd
#$ -j y
#$ -l mem_free=32G
#$ -l h_rt=12:00:00
#$ -pe smp 1
#$ -N pangenome_annotation_cmat
#Margot Bacino 25-12-16
echo "========================================"
echo "Job starting at $(date)"
echo "Running on host: $(hostname)"
echo "Job ID: $JOB_ID"
echo "========================================"

# Load conda environment
echo "Loading conda environment..."
module load CBI miniforge3/24.11.2-1
conda activate /wynton/group/lynch/software/jaccard_clustering_env

echo "Python version: $(python --version)"
echo "Pandas version: $(python -c 'import pandas; print(pandas.__version__)')"
echo "Biopython version: $(python -c 'import Bio; print(Bio.__version__)')"

# ============================================================================
# CONFIGURATION - Adjust these paths for your analysis
# ============================================================================

# Directory containing Panaroo output files
PANAROO_DIR="/path/to/panaroo_output"

# Directory containing Bakta TSV annotation files
BAKTA_DIR="/path/to/bakta_annotations_BUG_of_Interest"

# Output directory for results
OUTPUT_DIR="/path/to/BUG_of_Interest"

# Core gene threshold (0.95 = 95%, 0.99 = 99%)
CORE_THRESHOLD=0.95

echo ""
echo "Configuration:"
echo "  PANAROO_DIR: $PANAROO_DIR"
echo "  BAKTA_DIR: $BAKTA_DIR"
echo "  OUTPUT_DIR: $OUTPUT_DIR"
echo "  CORE_THRESHOLD: $CORE_THRESHOLD"
echo ""

# Check that input directories exist
if [ ! -d "$PANAROO_DIR" ]; then
    echo "ERROR: Panaroo directory not found: $PANAROO_DIR"
    exit 1
fi

if [ ! -d "$BAKTA_DIR" ]; then
    echo "ERROR: Bakta directory not found: $BAKTA_DIR"
    exit 1
fi

if [ ! -f "$PANAROO_DIR/gene_presence_absence.csv" ]; then
    echo "ERROR: gene_presence_absence.csv not found in $PANAROO_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "========================================"
echo "Starting pangenome annotation analysis..."
echo "========================================"

# Run Python script with unbuffered output
python -u panaroo_2_bakta.py \
    --panaroo_dir "$PANAROO_DIR" \
    --bakta_dir "$BAKTA_DIR" \
    --output_dir "$OUTPUT_DIR" \
    --core_threshold "$CORE_THRESHOLD"

EXIT_CODE=$?

echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "Job completed successfully at $(date)"
    echo "Results saved to: $OUTPUT_DIR"
else
    echo "Job failed with exit code: $EXIT_CODE"
    echo "Check logs for errors"
fi
echo "========================================"

exit $EXIT_CODE
