#!/usr/bin/bash
#$ -cwd
#$ -pe smp 16 ### number of cores available
#$ -l mem_free=16G ### number of GiB per core, 20*10 = 200 GiB total
#$ -l h_rt=50:00:00
##$ -e $HOME
##$ -o $HOME
#$ -m e

### Script from Punit Sundaramurthy, Lynch Lab UCSF ###

###################################################################
########################## HOW TO RUN #############################
###################################################################

# Quick command to run on your data:

# qsub -cwd bcl2fastq.sh 

###################################################################
###################################################################
###################################################################

# Start of script
# Let's load up required modules
# load required modules: to list all modules available on Wynton, type 'module load CBI' and then type 'module avail'
module load CBI bcl2fastq # load bcl2fastq

# Use bcl2fastq to turn raw sequencing runs to fastq files
echo "bcl2fastq Step"
# bcl2fastq command takes BaseCalls directory as input, the resulting fastq files will be stored in our results folder within the submission folder
# no late splitting = prevents the splitting of output files by individual lanes
# Ask ChatGPT this question to get more in depth answer about lane splitting: what is no-lane-splitting in bcl2fastq?
# --ignore-missing-bcls means to ignore files that are missing. Otherwise, bcl2fastq will throw an error & terminate. We only use this if the few missing 
#                       bcl files do not significantly impact the overall analysis or when the missing files are irrelevant for the intended downstream analysis.

# Let's define some variables which will make it easier for us to not have to type the file names or paths over & over again in the rest of our code
raw_dir=/wynton/group/lynch/NextSeq_data/250113_NS500170_0031_AH7GCTBGYW
NS_dir=/wynton/group/lynch/NextSeq_Processed/250113_NS500170_0031_AH7GCTBGYW_20250115_CANOE_Airway_16S_Run2
NS_map=/wynton/group/lynch/NextSeq_data/250113_NS500170_0031_AH7GCTBGYW/SampleSheet.csv

#### Copy runinfo file to NextSeq processed directory
cd ${NS_dir}
cp ${raw_dir}/RunInfo.xml .

dos2unix ${NS_map} # In Unix, at the end of each line in a file, we have an invisible '/n' character that indicates end of a line but in windows, it is '\r\n' so we are just going to convert \r\n to \n just in case

ulimit -n 16000 # This basically means that 16000 files can be open simultaneously but not anymore than that to limit use of resources
# Let's check out the raw data
# If the raw data is still has a .tar.gz extension, we want to unpack it so we have the raw data in the needed format
# We know a *tar.gz is a file and if it is unpacked already, it should be a folder so we can check both conditions
if [ -f "${raw_dir}.tar.gz" ] && [ ! -d "$raw_dir" ] ; then # check whether file refers to a regular file and make sure it is not a directory (if it has already been unpacked)
    echo "Extracting Raw NextSeq Run"
    tar -C ${raw_dir/$NS_dir/} -xvzf "${raw_dir}.tar.gz" # command used to untar the file
fi

bcl2fastq --input-dir $raw_dir/Data/Intensities/BaseCalls/ --output-dir ${NS_dir}/submission/ --no-lane-splitting --sample-sheet $NS_map --ignore-missing-bcls -p $NSLOTS

mv ${NS_dir}/submission/Stats ${NS_dir}
mv ${NS_dir}/Reports ${NS_dir}
rm -r InterOp
rm ${NS_dir}/submission/Undetermined* 
rm RunInfo.xml

cp ${NS_map} ${NS_dir}
# Your output should be fastq files located in ${NS_dir}/submission/ folder
