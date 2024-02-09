
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch3/hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch3.csv \
     --field_mapping ../hifiasm_input_mapping.csv \
     --workflow_name hifiasm

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies.                        ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mkdir assembly/batch3
cd assembly/batch3

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch3/* ./


mkdir hifiasm_submit_logs

## launch with slurm array job
sbatch \
     launch_hifiasm_array.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch3.csv


###############################################################################
##                               Relaunch Failures.                          ##
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

(awk 'NR == 1' HPRC_Intermediate_Assembly_s3Locs_Batch3.csv; \
     awk '$2 ~ /ERROR/ { print $1 }' hifiasm_status.txt \
     | while read sample; do grep "^$sample," HPRC_Intermediate_Assembly_s3Locs_Batch3.csv; done) \
          > HPRC_Intermediate_Assembly_s3Locs_Batch3_rerun.csv


awk '$2 ~ /ERROR/ { print $1 }' hifiasm_status.txt \
  | while read sample; do grep "^$sample," HPRC_Intermediate_Assembly_s3Locs_Batch3.csv; done \
  > HPRC_Intermediate_Assembly_s3Locs_Batch3_rerun.csv

sbatch \
     launch_hifiasm_array_rerun.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch3_rerun.csv


###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch3

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch3.csv \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm.csv \
      --json_location '{sample_id}_hifiasm_outputs.json'


###############################################################################
##                        create input jsons for initial QC                  ##   
###############################################################################

mkdir initial_qc
cd initial_qc

cp ../../batch2/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    

## copy to github repo for notetaking
cp \
    HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly/batch3/

cp -r initial_qc/ /private/groups/hprc/hprc_intermediate_assembly/assembly/batch3/


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch3

mkdir qc_submit_logs

sbatch \
    --array=[1-17]%8 \
    initial_qc/launch_initial_qc_array.sh \
    HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm.csv 


###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

# on hpc after entire batch has finished
cd /private/groups/hprc/assembly/batch3

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm.csv \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
      --json_location '{sample_id}_hifiasm_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch3_extracted_qc_results.csv

# cp \
#      intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch1/intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv

## add/commit/push to github (hprc_intermediate_assembly)

