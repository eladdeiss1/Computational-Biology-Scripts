#!/bin/bash

# Define paths
OUTPUT_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/emu_output_fastplong"
PHYLOSEQ_OUT="$OUTPUT_DIR/phyloseq"
CONFIDENCE_THRESHOLD=0.9

# Create output directories
mkdir -p "$PHYLOSEQ_OUT"

# Initialize combined files with headers
COMBINED_ABUNDANCE="$OUTPUT_DIR/combined_abundance.tsv"
COMBINED_TAXONOMY="$OUTPUT_DIR/combined_taxonomy.tsv"
COMBINED_READ_ASSIGNMENTS="$OUTPUT_DIR/combined_read_assignments.tsv"

FIRST_BATCH_INITIALIZED=false

# Merge all batch outputs
for BATCH_DIR in "$OUTPUT_DIR"/*_output; do
  echo "Merging batch: $BATCH_DIR"

  if [ "$FIRST_BATCH_INITIALIZED" = false ]; then
    head -n 1 "$BATCH_DIR/abundance.tsv" > "$COMBINED_ABUNDANCE"
    head -n 1 "$BATCH_DIR/taxonomy.tsv" > "$COMBINED_TAXONOMY"
    head -n 1 "$BATCH_DIR/read_assignments.tsv" > "$COMBINED_READ_ASSIGNMENTS"
    FIRST_BATCH_INITIALIZED=true
  fi

  tail -n +2 "$BATCH_DIR/abundance.tsv" >> "$COMBINED_ABUNDANCE"
  tail -n +2 "$BATCH_DIR/taxonomy.tsv" >> "$COMBINED_TAXONOMY"
  tail -n +2 "$BATCH_DIR/read_assignments.tsv" >> "$COMBINED_READ_ASSIGNMENTS"

done

# Confidence Filtering
echo "Filtering high-confidence reads..."
awk -v threshold=$CONFIDENCE_THRESHOLD 'NR==1 {print $0} NR>1 {if (max($2, $3, $4, $5, $6, $7, $8, $9, $10) >= threshold) print $0}' "$COMBINED_READ_ASSIGNMENTS" > "$OUTPUT_DIR/high_confidence_read_assignments.tsv"

# Generate Phyloseq-Compatible Files
cat "$COMBINED_ABUNDANCE" | awk 'NR==1 {print "FeatureID\t" $0} NR>1 {print}' > "$PHYLOSEQ_OUT/otu_table.tsv"
cat "$COMBINED_TAXONOMY" | awk 'NR==1 {print "FeatureID\t" $0} NR>1 {print}' > "$PHYLOSEQ_OUT/taxonomy_table.tsv"

echo "Batch merging and confidence filtering complete!"

