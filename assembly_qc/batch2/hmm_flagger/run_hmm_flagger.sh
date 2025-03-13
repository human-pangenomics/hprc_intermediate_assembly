####################################################################
##                      Make Read Tables                          ##
####################################################################

# get github repo 
cd /private/groups/hprc/qc_hmm_flagger/assembly_qc/batch2/hmm_flagger

##################################################################
##           Make HiFi and ONT tables for HMM-Flagger           ##
##################################################################


# Run jupyter notebook make_hmm_flagger_data_tables_batch2.ipynb
# This notebook:

# - Create HiFi and ONT table for censat batch2 data
# - There are some samples with new censat annotation from /private/groups/hprc/qc/batch2/censat/batch2_censat_outputs_done.csv
# - Makes diploid censat bed files and add links to the final tables
# - Takes read paths from tables
#    - batch1_jan_12_2025/hmm_flagger/read_tables/hifi_full_reads_table.jan_12_2025.csv
#    - batch1/hmm_flagger/read_tables/ont_reads_table.csv
#    - batch1/hmm_flagger/read_tables/hifi_reads_table.csv
# - Makes separate data tables for HiFi and ONT runs (both will contain diploid censat bed files)
# - Saves the final data tables in hifi/ and ont/ subdirectories and they will be used for creating input json files

###########################################
##        Create input jsons   (HiFi)    ##
###########################################

# set working directory
BATCH_NAME="batch2"
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
            --array=[1-18]%18  \
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
BATCH_NAME="batch2"
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

BATCH_NAME="batch2"
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

BATCH_NAME="batch2"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/hifi
bash create_output_hifi_csv.sh


###########################################
##        Create input jsons   (ONT)     ##
###########################################

# set working directory
BATCH_NAME="batch2"
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
            --array=[1-12]%12  \
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
BATCH_NAME="batch2"
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

BATCH_NAME="batch2"
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

BATCH_NAME="batch2"
cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/${BATCH_NAME}/hmm_flagger/ont
bash create_output_ont_csv.sh


