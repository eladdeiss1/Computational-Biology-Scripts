#!/bin/bash
#$ -cwd
#$ -pe smp 16
#$ -l mem_free=64G
#$ -l h_rt=96:00:00
#$ -N qiime2_emu_tree
#$ -m bea

module load CBI miniconda3/23.5.2-0-py311
conda activate /wynton/group/lynch/software/qiime2-amplicon-2024.10

# Define paths
PROJECT_DIR="/wynton/group/lynch/mbacino/25_04_14_OHPERIO_full_length_16S"
OUTDIR="$PROJECT_DIR/output_files/qiime2_output"
MANIFEST_FILE="$PROJECT_DIR/scripts/manifest.tsv"
ONT_QZA="$OUTDIR/ONT_seqs.qza"
TABLE_IN="$OUTDIR/table.qza"
REPSEQ_IN="$OUTDIR/rep-seqs.qza"
TREE_OUT="$OUTDIR/emu_tree"
TREE_QZA="$TREE_OUT/rooted-tree.qza"
EXPORT="$OUTDIR/exported"

mkdir -p  "$TREE_OUT" "$EXPORT"/{feature-table,rep-seqs,taxonomy,tree}

#########################################
# Step 3: Phylogenetic Tree Construction
#########################################
  
  qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences "$REPSEQ_IN" \
    --o-alignment "$TREE_OUT/aligned-rep-seqs.qza" \
    --o-masked-alignment "$TREE_OUT/masked-aligned-rep-seqs.qza" \
    --o-tree "$TREE_OUT/unrooted-tree.qza" \
    --o-rooted-tree "$TREE_QZA" \
    --p-parttree \
    --p-n-threads 16 \
    --p-mask-max-gap-frequency 0.95 \
    --p-mask-min-conservation 0.2 \
    --verbose \
    
  
  echo "✅ Tree construction complete."


