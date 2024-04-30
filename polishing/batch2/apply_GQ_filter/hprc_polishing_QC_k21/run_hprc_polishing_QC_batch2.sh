###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...
mkdir -p /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/hprc_polishing_QC_k21/hprc_polishing_QC_input_jsons
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/hprc_polishing_QC_k21/hprc_polishing_QC_input_jsons

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
mkdir -p /private/groups/hprc/polishing/batch2/apply_GQ_filter/hprc_polishing_QC/
cd /private/groups/hprc/polishing/batch2/apply_GQ_filter/hprc_polishing_QC/

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/hprc_polishing_QC_k21/* ./

mkdir hprc_polishing_QC_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_polishing_QC_batch2.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv

# resubmit HG02258 with new yak docker to fix error
mkdir -p slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

sbatch \
     --job-name=hprc-polishing_QC_k21-batch2 \
     --array=[7]%1 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --exclude=phoenix-[09,10,22,23,24] \
     --mem=400gb \
     --mail-type=FAIL,END \
     --mail-user=mmastora@ucsc.edu \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_polishing_QC.wdl \
     --sample_csv intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv \
     --input_json_path '../hprc_polishing_QC_input_jsons/${SAMPLE_ID}_hprc_polishing_QC.json'
###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch2/apply_GQ_filter/hprc_polishing_QC_k21

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json' \
      --submit_logs_directory hprc_polishing_QC_submit_logs
