#!/usr/bin/bash
#$ -cwd
#$ -pe smp 8 ### number of cores available
#$ -l mem_free=8G
#$ -l h_rt=08:00:00
##$ -e $HOME
##$ -o $HOME
#$ -m e

### Script from Punit Sundaramurthy, Lynch Lab UCSF ###

###################################################################
########################## HOW TO RUN #############################
###################################################################

# Quick command to run on your data:

# qsub -cwd fastqc.sh

###################################################################
##### BEFORE RUNNING THIS SCRIPT, PLEASE ENSURE THE FOLLOWING #####
###################################################################

# You must have a NS_dir folder from bcl2fastq step prior to this #
# script. It should have a "submission" folder within in with     #
# fastq files for your run. 					  #

###################################################################
###################################################################
###################################################################

# Start of script
# Let's load up required modules
# load required modules: to list all modules available on Wynton, type 'module load CBI' and then type 'module avail'
#module load CBI fastqc # load fastqc

# Use bcl2fastq to turn raw sequencing runs to fastq files
#echo "fastqc Step"
# fastqc is a tool used to check the quality of our reads in our fastq files. It will generate reports for each fastq &
# show us what we may need to filter/trim from reads. Make sure to check what your fastqc report files look like to get
# a sense of what your data quality looks like and modify fastp parameters in the next step accordingly if needed.

# Bash arguments to include when you run this script, look below for examples of what you should have in your qsub command
#NS_dir=$2

# Let's define some variables which will make it easier for us to not have to type the file names or paths over & over again in the rest of our code
NS_dir=/wynton/group/lynch/NextSeq_Processed/241220_NS500170_0029_AH7G5NBGYW_20250107_CANOE_Airway_16S
software_dir=/wynton/group/lynch/bcmm/mySoftware/


cd ${NS_dir}

# Run fastqc
#mkdir FASTQC/
#fastqc --nogroup submission/*.fastq.gz --outdir FASTQC --threads $NSLOTS
#echo fastqc complete...
# Run multiqc & check report
#singularity exec -B $PWD:$PWD ${software_dir}/multiqc.img multiqc FASTQC/

# Fastp step
mkdir -p fastp_submission
for ii in `ls submission | grep '_R1.fastq.gz'`; do
    echo $ii
    /wynton/group/lynch/punit/bioinformatic_tools/fastp -i submission/$ii -I submission/${ii/_R1/_R2} -o fastp_submission/$ii -O fastp_submission/${ii/_R1/_R2} --failed_out fastp_failed_reads --qualified_quality_phred 25 --unqualified_percent_limit 10 --average_qual 25 --trim_poly_x --length_required 100 --low_complexity_filter --html fastp.html
done;

mv fastp_failed_reads fastp.html fastp.json fastp_submission/ # moving all outputs produced by fastp into fastp_submission folder

mkdir -p FASTQC_filtered
fastqc --nogroup fastp_submission/*.fastq.gz --outdir FASTQC_filtered --threads $NSLOTS

# Run multiqc & check report
singularity exec -B $PWD:$PWD ${software_dir}/multiqc.img multiqc FASTQC_filtered/
