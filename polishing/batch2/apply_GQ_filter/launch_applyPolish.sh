#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's DeepPolisher workflow on a single machine
# Usage       : sbatch launch_hifiasm_array.sh sample_file.csv
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column

#SBATCH --job-name=HPRC-GQ_filters-applyPolish
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --partition=high_priority
#SBATCH --mail-user=mmastora@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=200gb
#SBATCH --threads-per-core=1
#SBATCH --output=applyPolish_submit_logs/applyPolish_submit_%x_%j_%A_%a.log
#SBATCH --time=7-0:00
#SBATCH --array=2,4,6,8,10,12,14,16,18%9

set -ex

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

## Create then change into sample directory...
mkdir -p ${sample_id}
cd ${sample_id}

mkdir -p toil_logs
mkdir -p ./applyPolish_mat_outputs
mkdir -p ./applyPolish_pat_outputs

export SINGULARITY_CACHEDIR=`pwd`/../cache/.singularity/cache
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/../cache/.cache/miniwdl
export TOIL_SLURM_ARGS="--time=7-0:00 --partition=high_priority"
export TOIL_COORDINATION_DIR=/data/tmp

toil clean "./jobstore"

# run mat
set -o pipefail
set +e
time toil-wdl-runner \
    --jobStore "./jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir ./toil_logs \
    /private/home/mmastora/progs/hpp_production_workflows/QC/wdl/tasks/applyPolish.wdl \
    ../applyPolish_input_jsons/${sample_id}_applyPolish.mat.json \
    --outputDirectory ./applyPolish_mat_outputs \
    --outputFile ${sample_id}_applyPolish_mat_outputs.json \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    2>&1 | tee log.txt
EXITCODE=$?
set -e

toil stats --outputFile stats.txt "./jobstore"

if [[ "${EXITCODE}" == "0" ]] ; then
    echo "Succeeded."
else
    echo "Failed."
    exit "${EXITCODE}"
fi


### run pat
toil clean "./jobstore"

set -o pipefail
set +e
time toil-wdl-runner \
    --jobStore "./jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir ./toil_logs \
    /private/home/mmastora/progs/hpp_production_workflows/QC/wdl/tasks/applyPolish.wdl \
    ../applyPolish_input_jsons/${sample_id}_applyPolish.pat.json \
    --outputDirectory ./applyPolish_pat_outputs \
    --outputFile ${sample_id}_applyPolish_pat_outputs.json \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    2>&1 | tee log.txt
EXITCODE=$?
set -e

toil stats --outputFile stats.txt "./jobstore"

if [[ "${EXITCODE}" == "0" ]] ; then
    echo "Succeeded."
else
    echo "Failed."
    exit "${EXITCODE}"
fi
