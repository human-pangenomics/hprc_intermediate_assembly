#!/bin/bash

# Author      : Julian Lucas, juklucas@ucsc.edu
# Description : Launch toil job submission for HPRC's DeepPolisher workflow using Slurm arrays
# Usage       : sbatch launch_hifiasm_array.sh sample_file.csv
#               	sample_file.csv should have a header (otherwised first sample will be skipped)
#					and the sample names should be in the first column

#SBATCH --job-name=HPRC-DeepPolisher-HG00408
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --partition=high_priority
#SBATCH --mail-user=mmastora@ucsc.edu
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=200gb
#SBATCH --output=hprc_DeepPolisher_submit_logs/HG00408_single_node_test.log
#SBATCH --time=3-0:00


## Create then change into sample directory...
mkdir -p HG00408
cd HG00408

mkdir toil_logs
mkdir hprc_DeepPolisher_outputs

export SINGULARITY_CACHEDIR=`pwd`/outputs/cache/.singularity/cache
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/outputs/cache/.cache/miniwdl
export TOIL_SLURM_ARGS="--time=3-0:00 --partition=high_priority --nodelist=phoenix-11 --exclude=phoenix-[00-10,12-21]"
export TOIL_COORDINATION_DIR=/data/tmp

time toil-wdl-runner \
    --jobStore ./polishing_bigstore \
    --batchSystem slurm \
    --batchLogsDir ./toil_logs \
    /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
    ../hprc_DeepPolisher_input_jsons/HG00408_hprc_DeepPolisher_singleNode.json \
    --outputDirectory hprc_DeepPolisher_outputs \
    --outputFile HG00408_hprc_DeepPolisher_outputs.json \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    --clusterStats ./HG00408_clusterstats.json \
    --restart \
    2>&1 | tee log.txt

wait
echo "Done."
