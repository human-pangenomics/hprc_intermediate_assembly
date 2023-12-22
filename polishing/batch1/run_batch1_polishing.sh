
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch1/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv \
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

mkdir batch1
cd batch1

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch1/* ./

mkdir hprc_DeepPolisher_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_deepPolisher_batch1.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv

## relaunch HG002_UL_chr20 with fixed fastq paths
sbatch \
     launch_hprc_deepPolisher_batch1_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv

## relaunch HG002_UL_chr20 and HG01975 because of weird failure and hanging for 24 hours
## added more disk space to extract reads wdl since that seemed to be the cause of the failure
sbatch \
     launch_hprc_deepPolisher_batch1_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv

# relaunch just HG01975 (#1) because it failed due "samtools not found" on extract reads which makes no sense
# adding logDebug to toil command
# restarting

sbatch \
     launch_hprc_deepPolisher_batch1_relaunch.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv


###############################################################################
##                             write output files to csv                     ##
###############################################################################

cd /private/groups/hprc/polishing/batch1

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1.updated.csv \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs.json'
