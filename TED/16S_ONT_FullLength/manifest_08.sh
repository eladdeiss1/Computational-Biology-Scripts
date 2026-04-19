#!/bin/bash

# Set the directory containing your fastplong FASTQ files
CLEANED_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/output_files/fastplong"
MANIFEST_FILE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/manifest.tsv"

# Create the manifest header
echo -e "sample-id\tabsolute-filepath\tdirection" > "$MANIFEST_FILE"

# Generate the manifest entries
for fq in "$CLEANED_DIR"/sample_*.fastq; do
    # Extract the sample ID (e.g., S100 from sample_S100_processed_clean.fastq)
    sample_id=$(basename "$fq" .fastq | sed -E 's/^sample_//; s/_processed$//')
 
    # Get the absolute path
    abs_path=$(realpath "$fq")
    
    # Add the line to the manifest
    echo -e "$sample_id\t$abs_path\tforward" >> "$MANIFEST_FILE"
done

echo "✅ Manifest generated at: $MANIFEST_FILE"

