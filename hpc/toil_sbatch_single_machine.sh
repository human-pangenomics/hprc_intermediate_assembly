#!/bin/bash

# Description : Launch WDL-based workflows using Toil's single_machine batch system.
#               All jobs are run on a single node and the job store is held on the node.
#               

#SBATCH --job-name=single-node-run
#SBATCH --cpus-per-task=8
#SBATCH --threads-per-core=1
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem=16gb
#SBATCH --time=7-00:00
#SBATCH --partition=long
#SBATCH --output=slurm_logs/submission_%x_%j_%A_%a.log


set -e

# Fetch input arguments with this while loop
# Adpated from "https://stackoverflow.com/a/7069755"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
     cat << 'EOF'

      Launch WDL-based workflows using Toil's single_machine batch system.
      All jobs are run on a single node and the job store is held on the node.
      This script is beneficial when you have a lot of I/O and your WDL tasks can
      utilize the resources allocated uniformly well. If your WDL is very bursty
      you should use another script in order to have Toil launch jobs with Slurm 
      on shared storage.

      Note that since this script runs Toil in the 'single_machine' mode it will 
      use a single node for all of the tasks in the workflow and it is neccesary to
      set the --cpus-per-task sbatch argument to the maximum number of cores needed 
      by any single task in the workflow. Multiple tasks can be run at the same time 
      as long as the sum of the requested CPUs and memory are less than the amount 
      requested by --cpus-per-task and --mem.

      This script is used for sbatch command with scattering across samples found in a 
      sample table. The outputs will be stored in the sample's directory:
          ${SAMPLE_ID}/analysis/${WDL_NAME}_outputs
      And a json file with all the workflows outputs will be created:
          ${SAMPLE_ID}/${SAMPLE_ID}_${WDL_NAME}_outputs.json

      Usage:

      sbatch toil_sbatch_single_machine.sh \
        --wdl /path/to/your/workflow.wdl \
        --sample_csv /path/your/sample_table.csv \
        --input_json_path '../your_input_jsons/${SAMPLE_ID}_myworkflow.json' \
        --toil_args '--container docker'        

      Options:

      -h, --help               Show brief help
      -w, --wdl                Path to the WDL file
      -s, --sample_csv         Path to a CSV file that has sample IDs in the first column
                               should have a header (otherwise the first sample will be skipped)
                               and the sample names should be in the first column
      -i, --input_json_path    The path for all JSON files created by launch_from_table.py
                               should be of the form: '../your_input_jsons/${SAMPLE_ID}_myworkflow.json'
                               so that this script can enter the sample ID.
      -t, --toil_args          (optional) Arguments to pass to Toil call                               

EOF
      exit 0
      ;;
    -w|--wdl)
      shift
      if [ $# -gt 0 ]; then
        export WDL_PATH=$1
      else
        echo "Error: No wdl path specified"
        exit 1
      fi
      shift
      ;;
    -s|--sample_csv)
      shift
      if [ $# -gt 0 ]; then
        export SAMPLE_CSV=$1
      else
        echo "Error: No sample csv specified"
        exit 1
      fi
      shift
      ;;
    -i|--input_json_path)
      shift
      if [ $# -gt 0 ]; then
        JSON_PATH_WITH_PLACEHOLDER=$1
      else
        echo "Error: No input json directory specified"
        exit 1
      fi
      shift
      ;;
    -t|--toil_args)
      shift
      if [ $# -gt 0 ]; then
        TOIL_ARGS="$1"
      else
        TOIL_ARGS=""
        echo "No toil args set. Running normally."
      fi
      shift
      ;;      
    *)
      break
      ;;
  esac
done

set -x

###############################################################################
##                             Prepare For Run                               ##
###############################################################################

# Read the CSV file and extract the sample ID for the current job array task
# Skip first row to avoid the header
SAMPLE_ID=$(awk -F ',' -v task_id=${SLURM_ARRAY_TASK_ID} 'NR>1 && NR==task_id+1 {print $1}' "${SAMPLE_CSV}")

# Ensure a sample ID is obtained
if [ -z "${SAMPLE_ID}" ]; then
    echo "Error: Failed to retrieve a valid sample ID. Exiting."
    exit 1
fi

# get input json path
export JSON_PATH=$(echo $JSON_PATH_WITH_PLACEHOLDER | sed "s/\${SAMPLE_ID}/$SAMPLE_ID/")

# Extract the WDL name
WDL_NAME=$(basename ${WDL_PATH%%.wdl})


## Create then change into sample directory...
mkdir -p ${SAMPLE_ID}
cd ${SAMPLE_ID}

## store current directory in order to write output files
export SHARED_FILESYSTEM_RUNFOLDER=`pwd`

## make folder on local node for jobstore
LOCAL_FOLDER=/data/tmp/$(whoami)/${WDL_NAME}_${SAMPLE_ID}
mkdir -p ${LOCAL_FOLDER}

## make folders on shared drive for logs and output
mkdir -p toil_logs
mkdir -p "${SHARED_FILESYSTEM_RUNFOLDER}/analysis/${WDL_NAME}_outputs"

# Set cache and coordination directories if not already set.
SINGULARITY_CACHEDIR=${SINGULARITY_CACHEDIR:-/data/tmp/$(whoami)/cache/singularity}
MINIWDL__SINGULARITY__IMAGE_CACHE=${MINIWDL__SINGULARITY__IMAGE_CACHE:-/data/tmp/$(whoami)/cache/miniwdl}
TOIL_COORDINATION_DIR=${TOIL_COORDINATION_DIR:-/data/tmp}

export SINGULARITY_CACHEDIR
export MINIWDL__SINGULARITY__IMAGE_CACHE
export TOIL_COORDINATION_DIR


toil clean "${LOCAL_FOLDER}/jobstore"

set -o pipefail
set +e            ## continue running even on failure so we clean node storage


###############################################################################
##                             Launch Workflow                               ##
###############################################################################

toil-wdl-runner \
    --jobStore "${LOCAL_FOLDER}/jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir "${SHARED_FILESYSTEM_RUNFOLDER}/toil_logs" \
    "${WDL_PATH}" \
    "${JSON_PATH}" \
    --outputDirectory "${SHARED_FILESYSTEM_RUNFOLDER}/analysis/${WDL_NAME}_outputs" \
    --outputFile "${SHARED_FILESYSTEM_RUNFOLDER}/${SAMPLE_ID}_${WDL_NAME}_outputs.json" \
    --runLocalJobsOnWorkers \
    --retryCount 1 \
    --disableProgress \
    ${TOIL_ARGS} \
    2>&1 | tee "${SAMPLE_ID}_${WDL_NAME}_log.txt"

## Calculate run statistics
toil stats --outputFile "${WDL_NAME}_stats.txt" "${LOCAL_FOLDER}/jobstore"

## cleanup local/node storage
toil clean "${LOCAL_FOLDER}/jobstore"

###############################################################################
##                                    DONE                                   ##
###############################################################################