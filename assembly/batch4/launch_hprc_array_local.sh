#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's Assembly workflows on a single machine
# Usage       : sbatch launch_hprc_array_local.sh sample_file.csv path_to_workflow.wdl input_json_path
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column
#                   the input_json_path should be of the form: '../hifiasm_input_jsons/${sample_id}_hifiasm.json'

#SBATCH --job-name=HPRC-run
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --threads-per-core=1
#SBATCH --cpus-per-task=64
#SBATCH --partition=high_priority
#SBATCH --mail-user=juklucas@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=800gb
#SBATCH --output=slurm_logs/submission_%x_%j_%A_%a.log
#SBATCH --time=7-0:00


set -ex

###############################################################################
##                               Parse Inputs                                ##
###############################################################################

## Pull samples names from CSV passed to script
sample_file=$1

# Read the CSV file and extract the sample ID for the current job array task
# Skip first row to avoid the header
sample_id=$(awk -F ',' -v task_id=${SLURM_ARRAY_TASK_ID} 'NR>1 && NR==task_id+1 {print $1}' "${sample_file}")

# Ensure a sample ID is obtained
if [ -z "${sample_id}" ]; then
    echo "Error: Failed to retrieve a valid sample ID. Exiting."
    exit 1
fi

echo "${sample_id}"


# Get the path and name of the workflow
wdl_path=$2
WDL_NAME=$(basename ${wdl_path%%.wdl})

# Ensure a worklow is obtained
if [ -z "${wdl_path}" ]; then
    echo "Error: Failed to find the WDL. Exiting."
    exit 1
fi


# Get the path to the input json
path_with_placeholder=$3
json_path=$(echo $path_with_placeholder | sed "s/\${sample_id}/$sample_id/")

# Ensure the input json is found...
if [ -z "${json_path}" ]; then
    echo "Error: Failed to find the input JSON. Exiting."
    exit 1
fi


###############################################################################
##                             Prepare For Run                               ##
###############################################################################

## Create then change into sample directory...
mkdir -p ${sample_id}
cd ${sample_id}

## make folder on local node for jobstore
LOCAL_FOLDER=/data/tmp/$(whoami)/hprc_assembly_${sample_id}
mkdir -p ${LOCAL_FOLDER}

## make folders on shared drive for logs and output
mkdir -p toil_logs
mkdir -p analysis


export SINGULARITY_CACHEDIR=`pwd`/../cache/.singularity/cache
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/../cache/.cache/miniwdl
export TOIL_SLURM_ARGS="--time=7-0:00 --partition=high_priority"
export TOIL_COORDINATION_DIR=/data/tmp

toil clean "${LOCAL_FOLDER}/jobstore"

set -o pipefail
set +e            ## continue running even on failure so we clean node storage


###############################################################################
##                             Launch Workflow                               ##
###############################################################################

time toil-wdl-runner \
    --jobStore "${LOCAL_FOLDER}/jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir ./toil_logs \
    "${wdl_path}" \
    "${json_path}" \
    --outputDirectory "analysis/${WDL_NAME}_outputs" \
    --outputFile "${sample_id}_${WDL_NAME}_outputs.json" \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    2>&1 | tee log.txt

## Calculate run statistics
toil stats --outputFile "${WDL_NAME}_stats.txt" "${LOCAL_FOLDER}/jobstore"

## cleanup local/node storage
toil clean "${LOCAL_FOLDER}/jobstore"

###############################################################################
##                                    DONE                                   ##
###############################################################################