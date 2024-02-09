#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's Hifiasm workflow using Slurm arrays
# Usage       : sbatch launch_hifiasm_array.sh sample_file.csv
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column

#SBATCH --job-name=HPRC-asm-batch3
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --partition=high_priority
#SBATCH --mail-user=juklucas@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=200gb
#SBATCH --output=hifiasm_submit_logs/hifiasm_submit_%x_%j_%A_%a.log
#SBATCH --time=3-0:00

## Pull samples names from CSV passed to script
sample_file=$1

## Check to see if this is a restart (to pass to Toil)
if [[ "$2" == "--restart" ]]; then
    EXTRA_ARGS="--restart"
else
    EXTRA_ARGS=""  # Set to an empty string or any default value you prefer
fi



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


mkdir -p assembly_logs 
mkdir -p analysis

export SINGULARITY_CACHEDIR=`pwd`/outputs/cache/.singularity/cache 
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/outputs/cache/.cache/miniwdl 
export TOIL_SLURM_ARGS="--time=3-0:00 --partition=high_priority"
export TOIL_COORDINATION_DIR=/data/tmp


toil-wdl-runner \
    --jobStore ./assembly_bigstore \
    --batchSystem slurm \
    --batchLogsDir ./assembly_logs \
    /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
    ../hifiasm_input_jsons/${sample_id}_hifiasm.json \
    --outputDirectory analysis/assembly \
    --outputFile ${sample_id}_hifiasm_outputs.json \
    --runLocalJobsOnWorkers \
    --disableProgress true \
    --caching=false \
    $EXTRA_ARGS \
    2>&1 | tee log.txt

wait
echo "Done."