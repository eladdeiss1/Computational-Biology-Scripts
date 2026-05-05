#!/bin/bash

BASE="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/quast_output"
OUTFILE="${BASE}/compiled_results.txt"

echo -e "barcode\tTotal_length\t#_contigs\tLargest_contig\tN50\tGC(%)" > "$OUTFILE"

for i in {01..17}; do
    BARCODE="barcode${i}"
    REPORT="${BASE}/${BARCODE}/report.txt"

    if [[ ! -f "$REPORT" ]]; then
        echo "[WARNING] Missing report for $BARCODE — skipping."
        continue
    fi

    # Total length (>= 0 bp)
    TOTAL_LEN=$(grep -E "^Total length \(>= 0 bp\)" "$REPORT" | awk '{print $NF}')

    # # contigs — only the first one AFTER line 12
    CONTIGS=$(tail -n +12 "$REPORT" | grep -E "^# contigs[[:space:]]" | head -1 | awk '{print $NF}')

    # Largest contig
    LARGEST=$(grep -E "^Largest contig" "$REPORT" | awk '{print $NF}')

    # N50
    N50=$(grep -E "^N50[[:space:]]" "$REPORT" | awk '{print $NF}')

    # GC (%)
    GC=$(grep -E "^GC \(%\)" "$REPORT" | awk '{print $NF}')

    echo -e "${BARCODE}\t${TOTAL_LEN}\t${CONTIGS}\t${LARGEST}\t${N50}\t${GC}" >> "$OUTFILE"
done

echo "Done. Output written to $OUTFILE"
