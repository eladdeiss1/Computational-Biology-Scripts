#!/bin/bash
#$ -N Jan05_gtdb
#$ -cwd
#$ -pe smp 8
#$ -l mem_free=32G
#$ -l h_rt=16:00:00 
#$ -l scratch=100G
#$ -t 1-17
#$ -m ea



### I made a new directory with the barcode assemblies, renamed them .fa, and then just ran the single gtdbtk classify command while in the conda environment, there was an issue with barcode naming and not being able to find the proper files ###
### I added this line before running the command: export GTDBTK_DATA_PATH="/wynton/group/lynch/databases/GTDBtk_r226/release226" ###

#gtdbtk classify_wf \
	#--genome_dir /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/gtdb_genomes/ \
	#--out_dir /wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f/output_files/GTDB_taxa_classification/ \
	#--cpus 4 \ 
	#--extension fa




module load CBI miniforge3/24.11.2-1
conda activate /wynton/group/lynch/software/gtdbtk-2.5.2

export GTDBTK_DATA_PATH="/wynton/group/lynch/databases/GTDBtk_r226/release226"


BARCODE=$(sed -n "${SGE_TASK_ID}p" samples.txt | tr -d '[:space:]')
[[ -n "$BARCODE" ]] || { echo "Error: No barcode for task $SGE_TASK_ID"; exit 1; }

echo "Processing $BARCODE"

BASE_DIR="/wynton/group/lynch/eladdy/Isolates_TED/Isolate_LongRead_Run1/WGS_Isolates/20251023_1427_MN32412_FBD97507_5616283f"
ASSEMBLY="${BASE_DIR}/output_files/autocycler/${BARCODE}/autocycler_out/consensus_assembly.fasta"

if [[ ! -f "$ASSEMBLY" ]]; then
    echo "ERROR: Assembly not found at:"
    echo "  $ASSEMBLY"
    exit 1
fi

# Scratch working dirs
TMP_JOB_DIR="${TMPDIR}/${BARCODE}_gtdbtk"
TMP_GENOMES="${TMP_JOB_DIR}/genomes"
TMP_OUT="${TMP_JOB_DIR}/output"

mkdir -p "$TMP_GENOMES" "$TMP_OUT"

# Copy and rename for GTDB-Tk
cp "$ASSEMBLY" "${TMP_GENOMES}/${BARCODE}.fa"

GTDBTK_OUTPUT_DIR="${BASE_DIR}/output_files/GTDB_taxa_classification/${BARCODE}"
mkdir -p "$GTDBTK_OUTPUT_DIR"

# Run GTDB-Tk
gtdbtk classify_wf \
    --genome_dir "$TMP_GENOMES" \
    --out_dir "$TMP_OUT" \
    --cpus 8 \
    --extension fa

# Move results back
mv "$TMP_OUT"/* "$GTDBTK_OUTPUT_DIR"

echo "Completed GTDB-Tk for $BARCODE"
echo "Results in: $GTDBTK_OUTPUT_DIR"

