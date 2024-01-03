###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch1_batch2_yakCount/yak_count_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.csv \
     --field_mapping ../yak_count_input_mapping.csv \
     --workflow_name yak_count

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir batch1_batch2_yakCount
cd batch1_batch2_yakCount

## get files to run in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch1_batch2_yakCount/* ./

mkdir yak_count_submit_logs

## launch with slurm array job
sbatch \
     launch_yak_count_batch1_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.csv


###############################################################################
##                             write output files to sample table            ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch1_batch2_yakCount

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.updated.csv \
      --json_location '{sample_id}_yak_count_outputs.json'
