#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's DeepPolisher workflow using Slurm arrays
# Usage       : sbatch launch_hifiasm_array.sh sample_file.csv
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column

#SBATCH --job-name=HPRC-DeepPolisher-batch2
#SBATCH --cpus-per-task=32
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --partition=high_priority
#SBATCH --mail-user=mmastora@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=200gb
#SBATCH --output=hprc_DeepPolisher_submit_logs/hprcDeepPolisher_submit_%x_%j_%A_%a.log
#SBATCH --time=7-0:00
#SBATCH --array=11%1

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

# make folder on local node for s3 data
LOCAL_FOLDER=/data/tmp/$(whoami)/HPRC_DeepPolisher_${sample_id}
mkdir -p ${LOCAL_FOLDER}

mkdir -p toil_logs
mkdir -p ${LOCAL_FOLDER}/hprc_DeepPolisher_outputs

# create new json
cp ../hprc_DeepPolisher_input_jsons/${sample_id}_hprc_DeepPolisher.json ${LOCAL_FOLDER}/${sample_id}_hprc_DeepPolisher.json

# loop through s3 links, download them to LOCAL_FOLDER,
# then replace them in the new json file
grep s3 ../hprc_DeepPolisher_input_jsons/${sample_id}_hprc_DeepPolisher.json \
| sed 's|,||g' | sed 's|["'\'']||g' | while read line ; do
    FILENAME=`basename $line`
    if [[ ! -e ${LOCAL_FOLDER}/${FILENAME} ]] ; then
        aws s3 cp --no-sign-request $line ${LOCAL_FOLDER}/
    fi
    sed -i "s|${line}|${LOCAL_FOLDER}/${FILENAME}|g" ${LOCAL_FOLDER}/${sample_id}_hprc_DeepPolisher.json
done

export SINGULARITY_CACHEDIR=`pwd`/../cache/.singularity/cache
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/../cache/.cache/miniwdl
export TOIL_SLURM_ARGS="--time=7-0:00 --partition=high_priority"
export TOIL_COORDINATION_DIR=/data/tmp

toil clean "${LOCAL_FOLDER}/jobstore"

set -o pipefail
set +e
time toil-wdl-runner \
    --jobStore "${LOCAL_FOLDER}/jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir ./toil_logs \
    /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
    ${LOCAL_FOLDER}/${sample_id}_hprc_DeepPolisher.json \
    --outputDirectory ${LOCAL_FOLDER}/hprc_DeepPolisher_outputs \
    --outputFile ${sample_id}_hprc_DeepPolisher_outputs.json \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    2>&1 | tee log.txt
EXITCODE=$?
set -e

toil stats --outputFile stats.txt "${LOCAL_FOLDER}/jobstore"

if [[ "${EXITCODE}" == "0" ]] ; then
    echo "Succeeded."
    
    # copy polished fasta, polishing vcf to /private/groups/hprc
    mkdir -p hprc_DeepPolisher_outputs
    cp ${LOCAL_FOLDER}/hprc_DeepPolisher_outputs/*.fasta hprc_DeepPolisher_outputs/
    cp ${LOCAL_FOLDER}/hprc_DeepPolisher_outputs/polisher_output.vcf.gz hprc_DeepPolisher_outputs/

    # Clean up
    rm -Rf ${LOCAL_FOLDER}
else
    echo "Failed."
    exit "${EXITCODE}"
fi
