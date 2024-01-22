
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv \
     --field_mapping ../hprc_DeepPolisher_input_mapping.csv \
     --workflow_name hprc_DeepPolisher

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing

## clone repo

git clone https://github.com/human-pangenomics/hprc_intermediate_assembly.git

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## get wdl workflow from github
git clone https://github.com/miramastoras/hpp_production_workflows.git

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir batch2
cd batch2

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch2/* ./

mkdir hprc_DeepPolisher_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_deepPolisher_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.csv

# resubmit HG02258 (#7)

sbatch \
     launch_hprc_deepPolisher_batch2_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.csv

# rerun without topup
# resubmit HG02258 (#7)

sbatch \
     launch_hprc_deepPolisher_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv

# relaunch # 2 which has been queued for 4 days

sbatch \
     launch_hprc_deepPolisher_batch2_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv

# relaunch # 5 which has been queued for a long time

sbatch \
     launch_hprc_deepPolisher_batch2_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv

# Using HG00408 to test runtime while using an entire node for the entire pipeline.
# scaled down split number of alignments to 5

sbatch launch_hprc_deepPolisher_batch2_HG00408.sh

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch2

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.updated.csv \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs.json' \
      --submit_logs_directory hprc_DeepPolisher_submit_logs
