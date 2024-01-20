
###############################################################################
##                             create input jsons                            ##   
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch1/hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3.csv \
     --field_mapping ../hifiasm_input_mapping.csv \
     --workflow_name hifiasm

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies                         ##   
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

