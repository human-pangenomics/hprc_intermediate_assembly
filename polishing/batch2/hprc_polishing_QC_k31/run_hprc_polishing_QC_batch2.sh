###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/hprc_polishing_QC_k31/hprc_polishing_QC_input_jsons

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

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

mkdir -p batch2/hprc_polishing_QC_k31
cd batch2/hprc_polishing_QC_k31

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch2/hprc_polishing_QC_k31/* ./

mkdir hprc_polishing_QC_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_polishing_QC_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv

# relaunch 1 which failed
sbatch \
     launch_hprc_polishing_QC_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv

# relaunch 5 for full merqury results
# relaunch 1 which failed
#SBATCH --array=5%1
sbatch \
     launch_hprc_polishing_QC_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv
###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch2

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json' \
      --submit_logs_directory hprc_polishing_QC_submit_logs
