#!/bin/bash
#$ -cwd
#$ -N emu_db_build_EDY
#$ -o /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/build_emu_db.out
#$ -e /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/build_emu_db.err

set -euo pipefail

# --- EDIT THESE IF NEEDED ---
ROOT="/wynton/group/lynch/databases/ehomd_EDY"
FA="${ROOT}/HOMD_16S_rRNA_RefSeq_V16.01_full.fasta"
QTX="${ROOT}/HOMD_16S_rRNA_RefSeq_V16.01.qiime.taxonomy"
BUILD="${ROOT}/emu_db_build_EDY"
DB="${ROOT}/ehomd_emu_db_EDY"
# ----------------------------

mkdir -p "$BUILD" "$DB"

module load CBI
module load miniforge3/24.11.2-1
conda activate /wynton/group/lynch/databases/ehomd_EDY/emu-py310

echo "==[1/6]== Check inputs"
[[ -s "$FA"  ]] || { echo "ERROR: FASTA missing/empty: $FA"; exit 2; }
[[ -s "$QTX" ]] || { echo "ERROR: QIIME taxonomy missing/empty: $QTX"; exit 3; }
echo "FASTA header example:  $(grep -m1 '^>' "$FA" || true)"
echo "QIIME taxonomy header: $(head -n1 "$QTX")"

echo "==[2/6]== Make seq2tax.map.tsv (FASTA header -> integer tax_id)"
# Use first token of header (w/o '>'), extract HMT number as integer tax_id.
awk '
  BEGIN{ OFS="\t" }
  /^>/{
    head=$1; sub(/^>/,"",head);                  # e.g., HMT-748_16S000001
    tid=0;
    if (match(head,/HMT-([0-9]+)/,m)) tid=m[1];  # e.g., 748
    if (tid==0) { print "WARN: cannot parse HMT from header [" head "]" > "/dev/stderr"; next }
    print head, tid
  }
' "$FA" > "$BUILD/seq2tax.map.tsv"

[[ -s "$BUILD/seq2tax.map.tsv" ]] || { echo "ERROR: seq2tax.map.tsv empty"; exit 4; }
echo "seq2tax.map.tsv rows: $(wc -l < "$BUILD/seq2tax.map.tsv")"

echo "==[3/6]== Make taxonomy.tsv (tax_id, species, genus, family, order, class, phylum, domain)"
# QIIME file: FeatureID \t Taxon (rank-prefixed; semicolon-separated)
# We parse HMT integer from FeatureID, strip d__/p__/..., and build a full species name:
#   species = (g__ + s__) if s__ present, else (genus + " sp.")
awk -F"\t" -v OFS="\t" '
  NR==1 { next }  # skip header if present
  {
    fid=$1; tax=$2;

    # integer tax_id from FeatureID like HMT-748_16S000001
    tid=0;
    if (match(fid,/HMT-([0-9]+)/,m)) tid=m[1];
    if (tid==0) next;

    # split lineage (domain..species); strip rank prefixes (d__/p__/...)
    n=split(tax, a, /; */);
    for(i=1;i<=n;i++){ sub(/^[a-z]__/, "", a[i]); }

    # map to ranks, allowing shorter/longer lineages
    dom = (n>=1?a[1]:"");
    phy = (n>=2?a[2]:"");
    cla = (n>=3?a[3]:"");
    ord = (n>=4?a[4]:"");
    fam = (n>=5?a[5]:"");
    gen = (n>=6?a[6]:"");
    spn = (n>=7?a[7]:"");   # species epithet only (e.g., rectus)

    # build a full species string; if no species epithet, use "Genus sp."
    species = (length(spn)>0 ? gen " " spn : (length(gen)>0 ? gen " sp." : ""))

    print tid, species, gen, fam, ord, cla, phy, dom
  }
' "$QTX" > "$BUILD/taxonomy.body.tsv"

[[ -s "$BUILD/taxonomy.body.tsv" ]] || { echo "ERROR: taxonomy.body.tsv empty"; exit 5; }

# add header row (emu accepts with/without header; header is handy)
{
  echo -e "tax_id\tspecies\tgenus\tfamily\torder\tclass\tphylum\tdomain"
  cat "$BUILD/taxonomy.body.tsv"
} > "$BUILD/taxonomy.tsv"

echo "taxonomy.tsv rows (incl header): $(wc -l < "$BUILD/taxonomy.tsv")"

echo "==[4/6]== Quick consistency check (tax_id sets)"
cut -f1 "$BUILD/taxonomy.tsv" | sed 1d | sort -u > "$BUILD/tax_from_taxonomy.txt"
cut -f2 "$BUILD/seq2tax.map.tsv" | sort -u > "$BUILD/tax_from_map.txt"
MISM=$(comm -3 "$BUILD/tax_from_taxonomy.txt" "$BUILD/tax_from_map.txt" | wc -l)
if [[ "$MISM" -gt 0 ]]; then
  echo "WARN: taxonomy vs map tax_id sets differ by $MISM lines (OK if refs/tax differ slightly)."
fi

echo "==[5/6]== Build Emu DB at $DB"
command -v emu >/dev/null 2>&1 || { echo "ERROR: emu not found in PATH (activate env)"; exit 6; }

emu build-database "$DB" \
  --sequences "$FA" \
  --seq2tax   "$BUILD/seq2tax.map.tsv" \
  --taxonomy-list "$BUILD/taxonomy.tsv"

echo "==[6/6]== Post-build checks"
[[ -s "$DB/species_taxid.fasta" ]] || { echo "ERROR: species_taxid.fasta missing"; exit 7; }
[[ -s "$DB/taxonomy.tsv"       ]] || { echo "ERROR: taxonomy.tsv missing"; exit 8; }

echo "Header example (should be integer:label):"
grep -m1 '^>' "$DB/species_taxid.fasta" | sed 's/^>//'
echo "SUCCESS: Emu DB ready: $DB"
echo "Run example:"
echo "  emu abundance --db \"$DB\" --threads 8 --output-dir /path/to/out sample.fastq"

