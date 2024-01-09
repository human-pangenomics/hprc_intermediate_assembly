###############################################################################
##                             create sample table                           ##
###############################################################################

## on personal computer, manually add sample yak column from
# intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.updated.csv
# to intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.updated.csv
# and add HG01975 from batch 1

###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch1_batch2_QC/hprc_polishing_QC_input_jsons/

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intAsm_batch1_batch2_polishingQC_sample_table.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

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

mkdir batch1_batch2_QC
cd batch1_batch2_QC

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch1_batch2_QC/* ./

mkdir hprc_polishing_QC_submit_logs

## launch with slurm array job
sbatch \
     launch_batch1_batch2_polishingQC.sh \
     intAsm_batch1_batch2_polishingQC_sample_table.csv

# relaunch all hprc samples because I forgot to include the hg38 for extracting cram.
# also relaunched because i needed to add more memory for merqury count
sbatch \
     launch_batch1_batch2_polishingQC_relaunch.sh \
     intAsm_batch1_batch2_polishingQC_sample_table.csv

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch1_batch2_QC

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intAsm_batch1_batch2_polishingQC_sample_table.csv \
      --output_data_table ./intAsm_batch1_batch2_polishingQC_sample_table.updated.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json'
