###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...
mkdir -p /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3/apply_GQ_filter/hprc_polishing_QC_k21/hprc_polishing_QC_input_jsons
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3/apply_GQ_filter/hprc_polishing_QC_k21/hprc_polishing_QC_input_jsons

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.filterVcf.polished.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
mkdir -p /private/groups/hprc/polishing/batch3/apply_GQ_filter/hprc_polishing_QC/
cd /private/groups/hprc/polishing/batch3/apply_GQ_filter/hprc_polishing_QC/

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch3/apply_GQ_filter/hprc_polishing_QC_k21/* ./

mkdir hprc_polishing_QC_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_polishing_QC_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.filterVcf.polished.csv

# relaunch samples which failed due to yak error
sbatch \
     --job-name=hprc-polishing_QC_k21-batch3 \
     --array=[29,32,3,5,4,8,10]%8 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --mem=400gb \
     --mail-type=FAIL,END \
     --mail-user=mmastora@ucsc.edu \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_polishing_QC.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.filterVcf.polished.csv \
     --input_json_path '../hprc_polishing_QC_input_jsons/${SAMPLE_ID}_hprc_polishing_QC.json'
###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch3/apply_GQ_filter/hprc_polishing_QC

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.filterVcf.polished.csv \
      --output_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.filterVcf.polished.QC.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json' \
      --submit_logs_directory hprc_polishing_QC_submit_logs
