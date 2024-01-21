
###############################################################################
##                        create input jsons for hifiasm                     ##   
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch1/hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv \
     --field_mapping ../hifiasm_input_mapping.csv \
     --workflow_name hifiasm

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             launch hifiasm                                ##   
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull 

mkdir assembly/batch1
cd assembly/batch1

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch1/* ./


mkdir hifiasm_submit_logs

## launch with slurm array job
## failed, relaunch after pushing fixes
sbatch \
     launch_hifiasm_array.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv

## relaunch
sbatch \
     launch_hifiasm_array_retry.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv     

## rerun two samples that failed...
sbatch \
     launch_hifiasm_array_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv 


###############################################################################
##                     Update table with hifiasm outputs                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/assembly/batch1

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv \
      --json_location '{sample_id}_hifiasm_outputs.json' \
      --submit_logs_directory hifiasm_submit_logs

cp \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch1/intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm.csv

## add/commit/push to github (hprc_intermediate_assembly)


###############################################################################
##                        create input jsons for initial QC                  ##   
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch1/initial_qc/qc_input_jsons

## note that I used an updated version of the data table to fix the child Ilmn 
## data for HG01261 which was corrup on the HPRC S3 bucket.
## New location: gs://fc-56ac46ea-efc4-4683-b6d5-6d95bed41c5e/CCDG_14151/Project_CCDG_14151_B01_GRM_WGS.cram.2020-02-12/Sample_HG01261/analysis/HG01261.final.cram

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm_fixed_data.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc

## add/commit/push to github (hprc_intermediate_assembly)


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

## on HPC...

cd /private/groups/hprc/assembly/batch1

mkdir initial_qc
cd initial_qc

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull 

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch1/initial_qc/* initial_qc/

mkdir qc_submit_logs

sbatch \
     initial_qc/launch_initial_qc_array.sh \
     initial_qc/intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_hifiasm_fixed_data.csv