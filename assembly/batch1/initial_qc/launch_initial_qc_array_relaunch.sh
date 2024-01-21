#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's initial Hifiasm QC using Slurm arrays
# Usage       : sbatch launch_initial_qc_array.sh sample_file.csv
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column

#SBATCH --job-name=HPRC-qc-batch1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --partition=high_priority
#SBATCH --mail-user=juklucas@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=200gb
#SBATCH --output=qc_submit_logs/qc_submit_%x_%j_%A_%a.log
#SBATCH --time=1-0:00
#SBATCH --array=[4]%1

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

## sample dir should have been created by assembly process
cd ${sample_id}


mkdir -p qc_logs 

export SINGULARITY_CACHEDIR=`pwd`/outputs/cache/.singularity/cache 
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/outputs/cache/.cache/miniwdl 
export TOIL_SLURM_ARGS="--time=3-0:00 --partition=high_priority"
export TOIL_COORDINATION_DIR=/data/tmp


toil-wdl-runner \
    --jobStore ./qc_bigstore \
    --batchSystem slurm \
    --batchLogsDir ./qc_logs \
    /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
    ../initial_qc/qc_input_jsons/${sample_id}_initial_qc.json \
    --outputDirectory analysis/qc \
    --outputFile ${sample_id}_hifiasm_qc_outputs.json \
    --runLocalJobsOnWorkers \
    --disableProgress true \
    --caching=false \
    2>&1 | tee log.txt

wait
echo "Done."