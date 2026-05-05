#!/bin/bash


#Can run using bash summarize_checkm2.sh

set -euo pipefail

# Base directory where your per-sample outputs live
OUTBASE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/checkM2"
# Output summary table
SUMMARY="${OUTBASE}/checkm2_summary.tsv"

echo "[INFO] Collecting CheckM2 quality reports from: $OUTBASE"
echo "[INFO] Writing summary to: $SUMMARY"

# Enable nullglob so the for-loop doesn't return literal pattern if no match
shopt -s nullglob

# Find all quality_report.tsv files
reports=("$OUTBASE"/*/checkm2_out/quality_report.tsv)

if [ ${#reports[@]} -eq 0 ]; then
    echo "[WARN] No quality_report.tsv files found under $OUTBASE"
    exit 0
fi

header_written=0

# Truncate/initialize the summary file
: > "$SUMMARY"

for q in "${reports[@]}"; do
    # Example path:
    # /.../output_files/MC_4470/checkM2/checkm2_out/quality_report.tsv

    # sample dir = dirname(dirname(dirname(q))) -> .../output_files/MC_4470
    sample_dir=$(dirname "$(dirname "$(dirname "$q")")")
    sample=$(basename "$sample_dir")

    echo "[INFO] Adding sample: $sample from $q"

    if [ $header_written -eq 0 ]; then
        # Read header from first file and write with 'sample' as first column
        read -r header < "$q"
        printf "sample\t%s\n" "$header" > "$SUMMARY"
        header_written=1
    fi

    # Append all data rows from this report, prefixing with the sample name
    tail -n +2 "$q" | awk -v s="$sample" '{print s "\t" $0}' >> "$SUMMARY"
done

echo "[DONE] Summary written to: $SUMMARY"

