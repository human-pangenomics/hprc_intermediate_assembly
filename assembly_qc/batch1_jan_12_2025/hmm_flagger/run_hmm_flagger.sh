####################################################################
##                      Make Read Tables                          ##
####################################################################

# get github repo 
cd /private/groups/hprc/qc_hmm_flagger/assembly_qc/batch1_jan_12_2025/hmm_flagger

# make ONT and HiF tables
mkdir read_tables
cd read_tables

# get ONT and HiFi index csv files
wget https://raw.githubusercontent.com/human-pangenomics/HPRC_metadata/refs/heads/main/data/hprc-data-explorer-tables/HPRC_PacBio_HiFi.file.index.csv

# run jupyter notebook read_tables/make_hifi_table.ipynb
# this notebook (Jan 12 2025):

# - Opens HiFi index file (HPRC_PacBio_HiFi.file.index.csv)
# - Makes a hifi table with only one sample per row and the corresponding reads saved in an array
# - It assumes that each mapping will be run in a 64 core machine so the number of tasks for mapping each file will be computed by dividing 64 by number of files
# - Some samples might have very high coverage. It sorts HiFi files based on coverage and keeps the files untill it reaches 80x and ignores the rest. These file arrays are saved in the column ending with "_downsampled"
# - kmer size and mapping preset will be set based on sequencing platform (HiFi: minimap2 (lr:hqae,k=25))
# - Note that HPRC_PacBio_HiFi.file.index.csv is a more complete version of HPRC_DeepConsensus.file.index.csv which was used in batch1/hmm_flagger/read_tables/
# - Related link for HPRC_PacBio_HiFi.file.index.csv (commit: 4687c2e) https://raw.githubusercontent.com/human-pangenomics/HPRC_metadata/refs/heads/main/data/hprc-data-explorer-tables/HPRC_PacBio_HiFi.file.index.csv

##################################################################
##           Make HiFi and ONT tables for HMM-Flagger           ##
##################################################################


# Run jupyter notebook make_hmm_flagger_data_tables_jan_12_2025.ipynb
# This notebook:
# - Opens censat_table_diploid_batch1.csv created by batch1/hmm_flagger/make_hmm_flagger_data_tables.ipynb
# - Takes read paths from tables
#    - batch1/hmm_flagger/read_tables/ont_reads_table.csv
#    - batch1_jan_12_2025/hmm_flagger/read_tables/hifi_full_reads_table.jan_12_2025.csv
# - Makes separate data tables for HiFi and ONT new runs that were missed in the previous runs for batch 1
# - Some HiFi runs were missed because I used only the DeepConsensus table but now I'm using a table with additional Revio data
# - Some ONT runs were missed because some samples had 'GM' prefix instead of 'NA' prefix
# - Saves the final data tables in hifi/ and ont/ subdirectories and they will be used for creating input json files


###########################################
##        Create input jsons   (HiFi)    ##
###########################################

# set working directory
BATCH_NAME="batch1_jan_12_2025"
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/hifi"
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
            --exclude=phoenix-[23] \
            --array=[1-83]%30  \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json


#####################################################################
##                   write output files to csv                     ##
#####################################################################

# set working directory
BATCH_NAME="batch1_jan_12_2025"
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/hifi"
cd ${WORKING_DIR}/runs_toil_slurm

## collect location of QC results
python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv  \
      --output_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.output.csv  \
      --json_location '{sample_id}_hmm_flagger_end_to_end_with_mapping_outputs.json'


###############################################################################
##                 Upload hifi output files to s3 bucket                     ##
###############################################################################

BATCH_NAME="batch1_jan_12_2025"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/hifi

rm -rf s3_upload
mkdir -p s3_upload
cd s3_upload

cat <<EOF > hmm_flagger_hifi_upload_linking_map.csv
column_name,destination
coverageGz,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
biasTableTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
finalPredictionBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
intermediatePredictionBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
loglikelihoodTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
miscFlaggerFilesTarGz,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
fullStatsTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
projectionSexBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
projectionSDBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
projectionAnnotationsBedArray,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
bigwigArray,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/
readAlignmentBam,upload/{sample_id}/hprc_r2/assembly_qc/read_alignments/hifi/
readAlignmentBai,upload/{sample_id}/hprc_r2/assembly_qc/read_alignments/hifi/
EOF

awk -F',' 'NR==1 {print $1",sample_hap,"substr($0, index($0,$2))} NR>1 {split($1, a, "_hap"); print a[1]","$1","substr($0, index($0,$2))}' \
    ../hmm_flagger_hifi_data_table.output.csv \
    > hmm_flagger_hifi_data_table.outputs_sample_oriented.csv


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file hmm_flagger_hifi_data_table.outputs_sample_oriented.csv \
     --mapping_csv hmm_flagger_hifi_upload_linking_map.csv

# run a bash script for upload to s3
sbatch ../../upload_hifi_data.sh 



###############################################################################
##                 Create hifi output table with s3 links                     ##
###############################################################################

BATCH_NAME="batch1_jan_12_2025"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/hifi
bash create_output_hifi_csv.sh


###########################################
##        Create input jsons   (ONT)     ##
###########################################

# set working directory
BATCH_NAME="batch1_jan_12_2025"
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/ont"
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
     --data_table ${WORKING_DIR}/hmm_flagger_ont_data_table.csv \
     --field_mapping ${WORKING_DIR}/hmm_flagger_ont_input_mapping.csv \
     --workflow_name ${WDL_NAME}



#########################################################################################
##                             Launch Mapping + HMM-Flagger     (ONT)                 ##
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
            --exclude=phoenix-[23] \
            --array=[1-13]%13  \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hmm_flagger_ont_data_table.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json



###############################################################################
##                             write output files to csv                     ##
###############################################################################

# set working directory
BATCH_NAME="batch1_jan_12_2025"
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/ont"
cd ${WORKING_DIR}/runs_toil_slurm

## collect location of QC results
python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ${WORKING_DIR}/hmm_flagger_ont_data_table.csv  \
      --output_data_table ${WORKING_DIR}/hmm_flagger_ont_data_table.output.csv  \
      --json_location '{sample_id}_hmm_flagger_end_to_end_with_mapping_outputs.json'

###############################################################################
##                 Upload ont output files to s3 bucket                     ##
###############################################################################

BATCH_NAME="batch1_jan_12_2025"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/ont

rm -rf s3_upload
mkdir -p s3_upload
cd s3_upload

cat <<EOF > hmm_flagger_ont_upload_linking_map.csv
column_name,destination
coverageGz,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
biasTableTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
finalPredictionBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
intermediatePredictionBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
loglikelihoodTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
miscFlaggerFilesTarGz,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
fullStatsTsv,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
projectionSexBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
projectionSDBed,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
projectionAnnotationsBedArray,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
bigwigArray,upload/{sample_id}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/
readAlignmentBam,upload/{sample_id}/hprc_r2/assembly_qc/read_alignments/ont/
readAlignmentBai,upload/{sample_id}/hprc_r2/assembly_qc/read_alignments/ont/
EOF

awk -F',' 'NR==1 {print $1",sample_hap,"substr($0, index($0,$2))} NR>1 {split($1, a, "_hap"); print a[1]","$1","substr($0, index($0,$2))}' \
    ../hmm_flagger_ont_data_table.output.csv \
    > hmm_flagger_ont_data_table.outputs_sample_oriented.csv


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file hmm_flagger_ont_data_table.outputs_sample_oriented.csv \
     --mapping_csv hmm_flagger_ont_upload_linking_map.csv

# run a bash script for upload to s3
sbatch ../../upload_ont_data.sh


###############################################################################
##                 Create ont output table with s3 links                     ##
###############################################################################

BATCH_NAME="batch1_jan_12_2025"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/ont
bash create_output_ont_csv.sh


