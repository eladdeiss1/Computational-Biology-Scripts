#!/bin/bash
#$ -cwd
#$ -V
#$ -pe smp 8
#$ -l mem_free=16G
set -euo pipefail

module load CBI
module load miniforge3/24.11.2-1
conda activate 16s-cons

CONS_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/consensus"
THREADS=${NSLOTS:-8}

# 1) Gather finished consensuses
echo "Collecting per-sample consensuses …"
shopt -s nullglob
CONS_FILES=(${CONS_DIR}/*.consensus.fasta)
cat "${CONS_DIR}"/S*.consensus.fasta > all_consensus.fa

# 2) (Optional) simplify headers to sample IDs (keeps directory-derived ID if present)
awk '/^>/{if(match($0,/S[0-9]+/)){print ">" substr($0,RSTART,RLENGTH)}; next} {print}' all_consensus.fa > all_consensus_simple.fa

# 3) Orient all sequences consistently
vsearch --orient all_consensus_simple.fa --db /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/consensus/S1.consensus.fasta --fasta_width 0 --fastaout all_consensus_oriented.fa

# 4) Align (MAFFT)
mafft --auto --thread "$THREADS" all_consensus_oriented.fa > aligned.fa

# 5a) Quick tree: FastTree
# FastTree -nt -gtr aligned.fa > tree_fasttree.nwk

# 5b) Higher-accuracy tree: IQ-TREE
mkdir -p /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/IQTree
iqtree2 -s aligned.fa -m GTR+G -bb 1000 -nt AUTO -pre /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/20250910_1339_MN32412_FBD97507_78286852/IQTree/aligned

echo "Done."
echo "Outputs:"
echo "  aligned.fa"
echo "  aligned.fa.treefile  (IQ-TREE Newick)"
echo "  aligned.fa.iqtree, aligned.fa.log (run details)"
# If you used FastTree instead:
# echo "  tree_fasttree.nwk"

