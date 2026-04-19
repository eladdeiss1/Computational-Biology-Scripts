#!/usr/bin/env bash
set -euo pipefail


module load CBI
module load miniforge3/24.11.2-1
conda activate /wynton/home/lynchlab/eladdeiss1/.conda/envs/16s-cons

# Inputs
FQ="samples_S1_processed.fastq"   # fastq or fastq.gz
THREADS="4"

BN="$(basename "$FQ")"
BN="${BN%.fastq}"


# Dirs
mkdir -p work_consensus consensus logs
SAMPLE="$(echo "$BN" | sed -E 's/^sample_//; s/_processed$//')"

echo "[INFO] Sample: $SAMPLE"
echo "[INFO] Input:  $FQ"

# 1) Convert reads to FASTA (and keep only ~full-length 16S if not already filtered)
#    If your reads are already ~1500 bp, you can drop the length filter.
#seqtk seq -A "$FQ" > "work/${SAMPLE}.fa"

# Optional guard: keep 1200–1800 bp only
#awk 'BEGIN{RS=">"; ORS=""} NR>1{
#  split($0, a, "\n"); hdr=a[1]; seq="";
#  for(i=2;i<=NF;i++) seq=seq a[i];
#  if(length(seq)>=1200 && length(seq)<=1800){ print ">"hdr"\n"seq"\n" }
#}' "work/${SAMPLE}.fa" > "work/${SAMPLE}.lenfilt.fa"

# 1.1) You will need to convert to .fa for all of the samples, use seqtk seq -A .fastq > .fa ***Note that this probably can be skipped, I just could not find out the right syntax when doing vsearch but it is possible!

# 2) Dereplicate (stabilizes POA and speeds up)
vsearch --derep_fulllength "work_consensus/${SAMPLE}.lenfilt.fa" \
        --output "work_consensus/${SAMPLE}.derep.fa" \
        --sizeout --threads "$THREADS" --minuniquesize 1

# 3) (Optional) De novo chimera filter
vsearch --uchime3_denovo "work_consensus/${SAMPLE}.derep.fa" \
        --nonchimeras "work_consensus/${SAMPLE}.nochim.fa" \
        --threads "$THREADS"

# 4) (Optional) Split haplotypes if the sample may contain >1 template
#    Tight identity keeps true single-template together, separates mixtures.
vsearch --cluster_fast "work_consensus/${SAMPLE}.nochim.fa" \
        --id 0.996 --centroids "work_consensus/${SAMPLE}.centroids.fa" \
        --uc "work_consensus/${SAMPLE}.clusters.uc" --threads "$THREADS"

# Helper: extract sequences by cluster into one file per cluster
awk 'BEGIN{FS="\t"} $1=="S"{cid=NR; centroid[$9]=cid} $1=="H"{cid=centroid[$4]; print $9"\t"cid}
' "work_consensus/${SAMPLE}.clusters.uc" > "work_consensus/${SAMPLE}.map"

# Build per-cluster files
rm -f work_consensus/${SAMPLE}.cluster_*.fa || true
while read -r ID CID; do
  awk -v id="$ID" 'BEGIN{RS=">"; ORS=""} NR>1{h=$1; sub(/[ \t].*/,"",h); if(h==id) print ">"$0 }' \
    "work_consensus/${SAMPLE}.nochim.fa" >> "work_consensus/${SAMPLE}.cluster_${CID}.fa"
done < "work_consensus/${SAMPLE}.map"

# If clustering found none (single template), fall back to all reads
ls work_consensus/${SAMPLE}.cluster_*.fa >/dev/null 2>&1 || cp "work_consensus/${SAMPLE}.nochim.fa" "work_consensus/${SAMPLE}.cluster_1.fa"

# 5) Build a POA consensus per cluster with spoa (robust for ONT amplicons)
BEST_CONS=""
BEST_N=0

for CFILE in work_consensus/${SAMPLE}.cluster_*.fa; do
  CID=$(basename "$CFILE" | sed -E 's/.*cluster_([0-9]+).fa/\1/')
  # spoa consensus
  spoa -r 1 "$CFILE" > "work_consensus/${SAMPLE}.cluster_${CID}.cons.fa"

  # Count contributing reads (for choosing best cluster)
  N=$(grep -c "^>" "$CFILE" || echo 0)
  if [ "$N" -gt "$BEST_N" ]; then
    BEST_N="$N"
    BEST_CONS="work_consensus/${SAMPLE}.cluster_${CID}.cons.fa"
  fi
done

# Draft consensus → name it consistently
cp "$BEST_CONS" "consensus/${SAMPLE}.draft.fa"

#Potentially some issue with the naming for the above line, needs to be better hammered out

# 6) Racon polishing (2 rounds)
minimap2 -x map-ont -a "consensus/${SAMPLE}.draft.fa" "$FQ" \
  | samtools sort -@ "$THREADS" -o "work_consensus/${SAMPLE}.bam"
samtools index "work_consensus/${SAMPLE}.bam"

for i in 1 2; do
  racon -t "$THREADS" "$FQ" "work_consensus/${SAMPLE}.bam" "consensus/${SAMPLE}.draft.fa" > "consensus/${SAMPLE}.racon${i}.fa"
  mv "consensus/${SAMPLE}.racon${i}.fa" "consensus/${SAMPLE}.draft.fa"
  minimap2 -x map-ont -a "consensus/${SAMPLE}.draft.fa" "$FQ" \
    | samtools sort -@ "$THREADS" -o "work/${SAMPLE}.bam"
  samtools index "work_consensus/${SAMPLE}.bam"
done

# 7) Medaka polishing (auto-pick a Kit14 SUP model if present)
#    We try to pick an r10/r104 SUP amplicon/400bps model if available.

MODEL="r1041_e82_400bps_sup_v4.3.0"

medaka_consensus \
  -i "$FQ" \
  -d "consensus/${SAMPLE}.draft.fa" \
  -o "consensus/${SAMPLE}.medaka" \
  -t "$THREADS" \
  -m "$MODEL"

# Final polished consensus
FINAL="consensus/${SAMPLE}.medaka/consensus.fasta"

# 8) Enforce full-length band and label
awk -v s="$SAMPLE" 'BEGIN{RS=">"; ORS=""} NR>1{
  split($0,a,"\n"); hdr=a[1]; seq="";
  for(i=2;i<=NF;i++) seq=seq a[i];
  if(length(seq)>=1200 && length(seq)<=1800){
    print ">" s "|16S_consensus\n" seq "\n"
  }
}' "$FINAL" > "consensus/${SAMPLE}.final_16S.fa"

echo "[OK] Wrote consensus/${SAMPLE}.final_16S.fa"

