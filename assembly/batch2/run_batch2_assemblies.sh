
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch2/hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.csv \
     --field_mapping ../hifiasm_input_mapping.csv \
     --workflow_name hifiasm

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch assemblies                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mkdir assembly/batch2
cd assembly/batch2

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch2/* ./


mkdir hifiasm_submit_logs

## launch with slurm array job
sbatch \
     launch_hifiasm_array.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.csv


###############################################################################
##                               Relaunch Failures                           ##
###############################################################################

# Loop through directories starting with 'HG'
for dir in HG* ; do
    # Check if a JSON file exists in the directory
    json_file=$(find "$dir" -name '*_hifiasm_outputs.json' -print -quit)

    # If a JSON file is found
    if [ -n "$json_file" ]; then
        # Check if the file is empty
        if [ -s "$json_file" ]; then
            status="DONE"
        else
            status="NOT DONE"
        fi
    else
        # If no JSON file is found
        status="ERROR No Json found"
    fi

    # Print the directory and the status
    echo "${dir}    ${status}" >> hifiasm_status.txt
done

awk '$2 ~ /NOT/ { print $1 }' hifiasm_status.txt \
  | while read sample; do grep "^$sample," HPRC_Intermediate_Assembly_s3Locs_Batch2.csv; done \
  > HPRC_Intermediate_Assembly_s3Locs_Batch2_rerun.csv

## add in the --restart command, remove directory creation
cp launch_hifiasm_array.sh launch_hifiasm_array_restart.sh

## 1475780
sbatch \
     launch_hifiasm_array_restart.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2_rerun.csv



###############################################################################
##                               Relaunch Failures (Again)                   ##
###############################################################################

rm hifiasm_status.txt

# Loop through directories starting with 'HG'
for dir in HG* ; do
    # Check if a JSON file exists in the directory
    json_file=$(find "$dir" -name '*_hifiasm_outputs.json' -print -quit)

    # If a JSON file is found
    if [ -n "$json_file" ]; then
        # Check if the file is empty
        if [ -s "$json_file" ]; then
            status="DONE"
        else
            status="NOT DONE"
        fi
    else
        # If no JSON file is found
        status="ERROR No Json found"
    fi

    # Print the directory and the status
    echo "${dir}    ${status}" >> hifiasm_status.txt
done

awk '$2 ~ /NOT/ { print $1 }' hifiasm_status.txt \
  | while read sample; do grep "^$sample," HPRC_Intermediate_Assembly_s3Locs_Batch2.csv; done \
  > HPRC_Intermediate_Assembly_s3Locs_Batch2_rerun2.csv

## add in the --restart command, remove directory creation
cp launch_hifiasm_array.sh launch_hifiasm_array_restart.sh

## 1475780
sbatch \
     launch_hifiasm_array_restart.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2_rerun.csv


###############################################################################
##                               Update table with outputs                   ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/assembly/batch2

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch2.csv \
      --output_data_table /private/groups/hprc/HPRC_Intermediate_Assembly_s3Locs_Batch2.csv.updated.csv \
      --json_location '{sample_id}_hifiasm_outputs.json' \
      --submit_logs_directory hifiasm_submit_logs

## add/commit/push to github (hprc_intermediate_assembly)


###############################################################################
##                        create input jsons for initial QC                  ##   
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch2/initial_qc/qc_input_jsons

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.updated_pt1.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc

## add/commit/push to github (hprc_intermediate_assembly)


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

## on HPC...

cd /private/groups/hprc/assembly/batch2

mkdir initial_qc

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull 

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch2/initial_qc/* initial_qc/

mkdir qc_submit_logs

sbatch \
     initial_qc/launch_initial_qc_array.sh \
     initial_qc/HPRC_Intermediate_Assembly_s3Locs_Batch2.updated_pt1.csv 


###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/assembly/batch2

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table initial_qc/HPRC_Intermediate_Assembly_s3Locs_Batch2.updated_pt1.csv \
      --output_data_table initial_qc/HPRC_Intermediate_Assembly_s3Locs_Batch2.updated_pt1_w_qc.csv \
      --json_location '{sample_id}_hifiasm_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table initial_qc/HPRC_Intermediate_Assembly_s3Locs_Batch2.updated_pt1_w_qc.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch2_pt1_extracted_qc_results.csv

# cp \
#      intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch1/intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv

## add/commit/push to github (hprc_intermediate_assembly)
