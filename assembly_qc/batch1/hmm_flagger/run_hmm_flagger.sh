####################################################################
##                             Make Read Tables                   ##
####################################################################


# get github repo 
cd /private/groups/hprc/qc_hmm_flagger
git clone https://github.com/human-pangenomics/hprc_intermediate_assembly

# make a subdirectory for hmm_flagger
mkdir -p assembly_qc/batch1/hmm_flagger
cd assembly_qc/batch1/hmm_flagger

# make ONT and HiF tables
mkdir read_tables
cd read_tables

# get ONT and HiFi index csv files
wget https://raw.githubusercontent.com/human-pangenomics/HPRC_metadata/refs/heads/v2-release/data/hprc-data-explorer-tables/HPRC_DeepConsensus.file.index.csv
wget https://raw.githubusercontent.com/human-pangenomics/HPRC_metadata/refs/heads/v2-release/data/hprc-data-explorer-tables/HPRC_ONT.file.index.csv    

# run jupyter notebook read_tables/make_ont_hifi_tables.ipynb
# this notebook:
# - Opens ONT and HiFi index files
# - Makes a new table with only one sample per row and the corresponding reads saved in an array
# - ONT_R9, ONT_R10 and HiFi reads have different configs (window size and alpha tsv) for hmm-flagger. Creates columns for saving these attributes
# - It assumes that each mapping will be run in a 64 core machine so the number of tasks for mapping each file will be computed by dividing 64 by number of files
# - Some samples might have very high coverage. It lists ONT files based on coverage and keeps the files untill it reaches 60x and ignores the rest. These file arrays are saved in the column ending with "_downsampled"
# - kmer size and mapping preset will be set based on sequencing platform (HiFi and ONT_R10: minimap2 (lr:hqae,k=25), ONT_R9 minimap2 (map-ont,k=15) )


###########################################################################
##        Make CenSat Diploid and rDNA Bed Files and Add to Tables       ##
###########################################################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/hifi"
cd ${WORKING_DIR}

# get censat data table
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/assembly_qc/batch1/censat/batch1_censat_outputs_done.csv

# get metadata for Year1 samples since I want to run Year1 samples first
wget https://raw.githubusercontent.com/human-pangenomics/HPP_Year1_Data_Freeze_v1.0/refs/heads/main/sample_metadata/hprc_year1_sample_metadata.txt

# run jupyter notebook make_hmm_flagger_data_tables.ipynb
# this notebook:
# - Opens batch1_censat_outputs_done.csv and hprc_year1_sample_metadata.txt
# - Makes diploid censat bed files and add links to the final table
# - Adds a column to the final table which keeps if the sample is Year1 or not
# - Puts Year1 samples on top of the table so that they will be run first
# - Takes read paths from tables /private/groups/hprc/qc_hmm_flagger/read_tables/ont_reads_table.csv and /private/groups/hprc/qc_hmm_flagger/read_tables/hifi_reads_table.csv
# - Makes separate data tables for HiFi and ONT runs (both will contain diploid censat bed files)
# - The final data tables will be saved in hifi and ont subdirectories and they will be used for creating input json files


###########################################
##        Create input jsons   (HiFi)    ##
###########################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/hifi"
cd ${WORKING_DIR}

# check that flagger repo is up to date
FLAGGER_DIR="/private/groups/patenlab/masri/apps/flagger_v1.1.0/flagger"
git -C ${FLAGGER_DIR} pull

## Save WDL path and name in environment variables
WDL_PATH=${FLAGGER_DIR}/wdls/workflows/hmm_flagger_end_to_end_with_mapping.wdl
WDL_FILENAME=$(basename ${WDL_PATH})
WDL_NAME=${WDL_FILENAME%%.wdl}


## Make a folder for saving files related to run e.g. input and output jsons
cd ${WORKING_DIR}
mkdir -p runs_toil_slurm
cd runs_toil_slurm

## Make a directory for saving input json files
mkdir -p ${WDL_NAME}_input_jsons
cd ${WDL_NAME}_input_jsons

python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv \
     --field_mapping ${WORKING_DIR}/hmm_flagger_hifi_input_mapping.csv \
     --workflow_name ${WDL_NAME}


#########################################################################################
##                             Launch Mapping + HMM-Flagger     (HiFi)                 ##
#########################################################################################


## Make sure you are in the working directory
cd ${WORKING_DIR}

## Set environment variables for sbatch
USERNAME="masri"
EMAIL="masri@ucsc.edu"
TIME_LIMIT="70:00:00"

## Partition should be modifed based on the available partitions on the server
PARTITION="high_priority"


## Go to the execution directory
mkdir -p runs_toil_slurm/${WDL_NAME}_logs
cd runs_toil_slurm

## Run jobs arrays
sbatch      --job-name=${WDL_NAME}_${USERNAME} \
            --cpus-per-task=64 \
            --mem=256G \
            --mail-user=${EMAIL} \
            --mail-type=FAIL,END \
            --output=${WDL_NAME}_logs/${WDL_NAME}_%A_%a.log \
            --array=[1-141]%30  \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json


############################################################
##      HG002_T2T_v1.1.0:  Create input jsons   (HiFi)    ##
############################################################


# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/hifi"
cd ${WORKING_DIR}

# check that flagger repo is up to date
FLAGGER_DIR="/private/groups/patenlab/masri/apps/flagger_v1.1.0/flagger"
git -C ${FLAGGER_DIR} pull

## Save WDL path and name in environment variables
WDL_PATH=${FLAGGER_DIR}/wdls/workflows/hmm_flagger_end_to_end_with_mapping.wdl
WDL_FILENAME=$(basename ${WDL_PATH})
WDL_NAME=${WDL_FILENAME%%.wdl}


## Make a folder for saving files related to run e.g. input and output jsons
cd ${WORKING_DIR}
mkdir -p runs_toil_slurm_HG002_v1.1
cd runs_toil_slurm_HG002_v1.1

## Make a directory for saving input json files
mkdir -p ${WDL_NAME}_input_jsons
cd ${WDL_NAME}_input_jsons

python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table_HG002_v1.1.csv \
     --field_mapping ${WORKING_DIR}/hmm_flagger_hifi_input_mapping.csv \
     --workflow_name ${WDL_NAME}


##################################################################################################
##         HG002_T2T_v1.1.0:      Launch Mapping + HMM-Flagger     (HiFi)                       ##
##################################################################################################

#####
# Exclude phoenix-[23]
# This node is always failing
#####

## Make sure you are in the working directory
cd ${WORKING_DIR}

## Set environment variables for sbatch
USERNAME="masri"
EMAIL="masri@ucsc.edu"
TIME_LIMIT="70:00:00"

## Partition should be modifed based on the available partitions on the server
PARTITION="high_priority"


## Go to the execution directory
mkdir -p runs_toil_slurm_HG002_v1.1/${WDL_NAME}_logs
cd runs_toil_slurm_HG002_v1.1

## Run jobs arrays
sbatch      --job-name=${WDL_NAME}_${USERNAME} \
            --cpus-per-task=64 \
            --mem=256G \
            --mail-user=${EMAIL} \
            --mail-type=FAIL,END \
            --output=${WDL_NAME}_logs/${WDL_NAME}_%A_%a.log \
            --array=[1]%1  \
            --exclude=phoenix-[23] \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hmm_flagger_hifi_data_table_HG002_v1.1.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm_HG002_v1.1/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json



###############################################################################
##                             write output files to csv                     ##
###############################################################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/hifi"
cd ${WORKING_DIR}/runs_toil_slurm

## collect location of QC results
python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv  \
      --output_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.output.csv  \
      --json_location '{sample_id}_hmm_flagger_end_to_end_with_mapping_outputs.json'
