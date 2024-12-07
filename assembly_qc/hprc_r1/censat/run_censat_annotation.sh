
# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hprc_r1/censat"
cd ${WORKING_DIR}

# check that flagger repo is up to date
ALPHA_ANNOTATION_DIR="/private/groups/patenlab/masri/apps/alphaAnnotation"

## Save WDL path and name in environment variables
WDL_PATH=${ALPHA_ANNOTATION_DIR}/cenSatAnnotation/centromereAnnotation_customized_hprc_r1.wdl
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
     --data_table ${WORKING_DIR}/hprc_y1_annotation_table.csv \
     --field_mapping ${WORKING_DIR}/hprc_y1_input_mapping.csv \
     --workflow_name ${WDL_NAME}




## Make sure you are in the working directory
cd ${WORKING_DIR}

## Set environment variables for sbatch
USERNAME="masri"
EMAIL="masri@ucsc.edu"
TIME_LIMIT="12:00:00"

## Partition should be modifed based on the available partitions on the server
PARTITION="high_priority"


## Go to the execution directory
mkdir -p runs_toil_slurm/${WDL_NAME}_logs
cd runs_toil_slurm

## Run jobs arrays
sbatch      --job-name=${WDL_NAME}_${USERNAME} \
            --cpus-per-task=16 \
            --mem=32G \
            --mail-user=${EMAIL} \
            --mail-type=FAIL,END \
            --output=${WDL_NAME}_logs/${WDL_NAME}_%A_%a.log \
            --array=[1-94]%50  \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hprc_y1_annotation_table.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json



###############################################################################
##                             write output files to csv                     ##
###############################################################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hprc_r1/censat"
cd ${WORKING_DIR}/runs_toil_slurm

## collect location of QC results
python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ${WORKING_DIR}/hprc_y1_annotation_table.csv  \
      --output_data_table ${WORKING_DIR}/hprc_y1_annotation_table.output.csv  \
      --json_location '{sample_id}_centromereAnnotation_customized_hprc_r1_outputs.json'
