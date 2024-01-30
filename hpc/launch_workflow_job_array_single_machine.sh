#!/bin/bash

# Author      : Mobin Asri, masri@ucsc.edu
# Description : Launch toil job submission for any WDL-based workflow using Slurm arrays (Based on Julian and Mira's scripts)

#SBATCH --cpus-per-task=8
#SBATCH --threads-per-core=1
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=16gb
#SBATCH --time=7-00:00

# Fetch input arguments with this while loop
# Adpated from "https://stackoverflow.com/a/7069755"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      echo " "
      echo """
               Launch toil job submission for any workflow written in WDL format using Slurm arrays.
	       
	       Note that this bash script runs Toil in the 'single_machine' mode.
               Therefore it will use a single node for all of the tasks in the workflow and it is nessacary to
               set the --cpus-per-task sbatch argument to the maximum number of cores needed by any single task in the workflow.
               It might happen that your workflow run multiple tasks at the same time. If that is the case the more cores
               you set by --cpus-per-task for sbatch you will allow more tasks to be run at the same time.
               
	       It is assumed that you are running this command where you want to have the
               output json file containing the paths to the output files of your workflow.
	       the output json file will be located in \${WDL_NAME}
	   """
      echo "sbatch launch_wdl_job_array.sh \\"
      echo "                    --wdl /path/to/your/workflow.wdl \\"
      echo "                     --sample_csv /path/your/sample_table.csv \\"
      echo "                     --input_json_dir /path/to/input_json_dir"
      echo " "
      echo "options:"
      echo """-h, --help                               
                                     Show brief help
	   """
      echo """-w, --wdl=WDL          
                                      Path to the wdl file
	   """
      echo """-s, --sample_csv=SAMPLE_CSV
                                     Path to a csv file that has samples ids in the first column
                                     should have a header (otherwised first sample will be skipped)
                                     and the sample names should be in the first column      
	   """
      echo """-i, --input_json_dir=INPUT_JSON_DIR  
                                     The directory where all json files created by launch_from_table.py
                                     are located and it is necessary that each json file has this format
      		                     \${SAMPLE_ID}_\${WDL_NAME}.json. \${SAMPLE_ID} should be present
                                     in the first column of sample_table.csv and \${WDL_NAME} is the basename
			             of the given wdl file with no \".wdl\" extension. For example in
				     \"/path/to/your/workflow.wdl\" \${WDL_NAME} is \"workflow\"
	    """
      exit 0
      ;;
    -w)
      shift
      if [ $# -gt 0 ]; then
        export WDL_PATH=$1
      else
        echo "Error: No wdl path specified"
        exit 1
      fi
      shift
      ;;
    --wdl)
      shift
      if [ $# -gt 0 ]; then
        export WDL_PATH=$1
      else
        echo "Error: No wdl path specified"
        exit 1
      fi
      shift
      ;;
    -s)
      shift
      if [ $# -gt 0 ]; then
        export SAMPLE_CSV=$1
      else
        echo "Error: No sample csv specified"
        exit 1
      fi
      shift
      ;;
    --sample_csv)
      shift
      if [ $# -gt 0 ]; then
        export SAMPLE_CSV=$1
      else
        echo "Error: No sample csv specified"
        exit 1
      fi
      shift
      ;;
    -i)
      shift
      if [ $# -gt 0 ]; then
        export INPUT_JSON_DIR=$1
      else
        echo "Error: No input json directory specified"
        exit 1
      fi
      shift
      ;;
    --input_json_dir)
      shift
      if [ $# -gt 0 ]; then
        export INPUT_JSON_DIR=$1
      else
        echo "Error: No input json directory specified"
        exit 1
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done


# Get the name of the workflow
WDL_NAME=$(basename ${WDL_PATH%%.wdl})


# Read the CSV file and extract the sample ID for the current job array task
# Skip first row to avoid the header
SAMPLE_ID=$(awk -F ',' -v task_id=${SLURM_ARRAY_TASK_ID} 'NR>1 && NR==task_id+1 {print $1}' "${SAMPLE_CSV}")

# Ensure a sample ID is obtained
if [ -z "${SAMPLE_ID}" ]; then
    echo "Error: Failed to retrieve a valid sample ID. Exiting."
    exit 1
fi

echo "[$(date)] The retrieved sample id is ${SAMPLE_ID}"


# Make folder on local storage for saving data with external links
LOCAL_FOLDER=/data/tmp/$(whoami)/${SAMPLE_ID}_${WDL_NAME}
mkdir -p ${LOCAL_FOLDER}

# Create a copy of the input json for ${SAMPLE_ID}
cp ${INPUT_JSON_DIR}/${SAMPLE_ID}_${WDL_NAME}.json ${LOCAL_FOLDER}/${SAMPLE_ID}_${WDL_NAME}.json

# Save all external links starting with http, s3 or gs in an array
# remove ending comma, single and double quotation marks 
ALL_EXTERNAL_URLS=$(grep -Eo '(http|s3:|gs:)\S+?' ${LOCAL_FOLDER}/${SAMPLE_ID}_${WDL_NAME}.json | sed 's/['\''\"\,]//g')

echo "[$(date)] Start downloading external data ..."
# Loop through external links, download them to LOCAL_FOLDER,
# then replace them in the new json file
for EXTERNAL_URL in ${ALL_EXTERNAL_URLS[@]}; do
    FILENAME=$(basename ${EXTERNAL_URL})
    if [[ ! -e ${LOCAL_FOLDER}/${FILENAME} ]] ; then
	echo "[$(date)] Start downloading ${EXTERNAL_URL} ..."
        ## Download the input file with appropriate command
        if [[ "${EXTERNAL_URL}" =~ ^s3.* ]]; then 
            aws s3 cp --no-sign-request ${EXTERNAL_URL} ${LOCAL_FOLDER}/
        elif [[ "${EXTERNAL_URL}" =~ ^http.* ]]; then
            wget --quiet --directory-prefix=${LOCAL_FOLDER}/ ${EXTERNAL_URL}
        elif [[ "${EXTERNAL_URL}" =~ ^gs.* ]]; then
            gsutil cp ${EXTERNAL_URL} ${LOCAL_FOLDER}/
        fi
	echo "[$(date)] Downloaded ${EXTERNAL_URL}"
    fi
    # Replace external link with local path in the local version of the input json file
    sed -i "s|${EXTERNAL_URL}|${LOCAL_FOLDER}/${FILENAME}|g" ${LOCAL_FOLDER}/${SAMPLE_ID}_${WDL_NAME}.json
done

# Set some env variables for Toil
export SINGULARITY_CACHEDIR=`pwd`/../cache/.singularity/cache
export MINIWDL__SINGULARITY__IMAGE_CACHE=`pwd`/outputs/cache/.cache/miniwdl 
export TOIL_COORDINATION_DIR="/data/tmp"


## Create then change into sample directory...
mkdir -p ${SAMPLE_ID}
cd ${SAMPLE_ID}
mkdir -p toil_logs

echo "[$(date)] Start running Toil job ..."

toil clean "${LOCAL_FOLDER}/jobstore"

# Run Toil job
toil-wdl-runner \
    --jobStore "${LOCAL_FOLDER}/jobstore" \
    --stats \
    --clean=never \
    --batchSystem single_machine \
    --maxCores "${SLURM_CPUS_PER_TASK}" \
    --batchLogsDir ./toil_logs \
    ${WDL_PATH} \
    ${LOCAL_FOLDER}/${SAMPLE_ID}_${WDL_NAME}.json \
    --outputDirectory ${LOCAL_FOLDER}/${WDL_NAME}_outputs \
    --outputFile ${SAMPLE_ID}_${WDL_NAME}_outputs.json \
    --runLocalJobsOnWorkers \
    --retryCount 0 \
    --disableProgress \
    2>&1 | tee log.txt

echo "[$(date)] Toil job is finished."

EXITCODE=$?
set -e

# Save runtime stats
toil stats --outputFile stats.txt "${LOCAL_FOLDER}/jobstore"

if [[ "${EXITCODE}" == "0" ]] ; then
    echo "[$(date)] Your Toil job succeeded! :)"
    echo "[$(date)] Start copying output files to the current directory and updating output json file..." 
    # copy all output files to the current directory (presumably on shared storage)
    mkdir -p ${WDL_NAME}_outputs
    LOCAL_OUTPUT_FILES=$(find ${LOCAL_FOLDER}/${WDL_NAME}_outputs/ -maxdepth 1 -type f)
    for LOCAL_OUTPUT_FILE in ${LOCAL_OUTPUT_FILES[@]}; do
       
        echo "[$(date)] Start copying ${LOCAL_OUTPUT_FILE} to ${PWD}/${WDL_NAME}_outputs/"
        # Copy output file to the current directory
        OUTPUT_FILENAME=$(basename ${LOCAL_OUTPUT_FILE})
        COPIED_OUTPUT_FILE="${PWD}/${WDL_NAME}_outputs/${OUTPUT_FILENAME}"
	cp ${LOCAL_OUTPUT_FILE} ${COPIED_OUTPUT_FILE}    
        echo "[$(date)] Copied ${LOCAL_OUTPUT_FILE}"
      
        # Update output json with new path
        sed -i "s|${LOCAL_OUTPUT_FILE}|${COPIED_OUTPUT_FILE}|g" ${SAMPLE_ID}_${WDL_NAME}_outputs.json
    done

    echo "[$(date)] Output json file is located here: ${PWD}/${SAMPLE_ID}_${WDL_NAME}_outputs.json"
    echo "[$(date)] Cleaning up ${LOCAL_FOLDER}"
    # Clean up
    rm -Rf ${LOCAL_FOLDER}

    echo "[$(date)] Finished!"
else
    echo "[$(date)] Your Toil job failed! :("
    exit "${EXITCODE}"
fi
