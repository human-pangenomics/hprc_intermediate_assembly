
###########################################################################
##        Make CenSat Diploid and rDNA Bed Files and Add to Tables       ##
###########################################################################

cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hprc_r1/hmm_flagger

# run jupyter notebook make_hmm_flagger_hprc_r1_data_tables.ipynb
### This notebook:
# - Opens `hprc_y1_annotation_table.output.csv`
# - Makes diploid censat bed files and add links to the final tables
# - Opens `Year1_assemblies_v2_genbank.index`
# - Adds assembly links to the final tables
# - Takes read paths from tables `/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/read_tables/ont_reads_table.csv` and `/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/read_tables/hifi_reads_table.csv`
# - Makes separate data tables for HiFi and ONT runs (both will contain diploid censat bed files)
# - Saves the final data tables in `hifi/` and `ont/` subdirectories and they will be used for creating input json files

###########################################
##        Create input jsons   (HiFi)    ##
###########################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hprc_r1/hmm_flagger/hifi"
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
            --array=[1-5]%5  \
            --time=${TIME_LIMIT} \
            --partition=${PARTITION} \
            /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
            --wdl ${WDL_PATH} \
            --sample_csv  ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv \
            --input_json_path ${WORKING_DIR}/runs_toil_slurm/${WDL_NAME}_input_jsons/\${SAMPLE_ID}_${WDL_NAME}.json

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# set working directory
WORKING_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hprc_r1/hmm_flagger/hifi"
cd ${WORKING_DIR}/runs_toil_slurm

## collect location of QC results
python3 /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.csv  \
      --output_data_table ${WORKING_DIR}/hmm_flagger_hifi_data_table.output.csv  \
      --json_location '{sample_id}/{sample_id}_hmm_flagger_end_to_end_with_mapping_outputs.json'
