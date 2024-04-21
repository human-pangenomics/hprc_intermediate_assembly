###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch5/hprc_polishing_QC_k31/hprc_polishing_QC_input_jsons

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.polished.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing/batch5

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir -p hprc_polishing_QC_k31
cd hprc_polishing_QC_k31

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch5/hprc_polishing_QC_k31/* ./

mkdir -p slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

# submit job
sbatch \
     --job-name=hprc-polishing_QC_k31-batch5 \
     --array=[1-19,21-24]%10 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --mem=400gb \
     --mail-type=FAIL,END \
     --mail-user=mmastora@ucsc.edu \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_polishing_QC.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.polished.csv \
     --input_json_path '../hprc_polishing_QC_input_jsons/${SAMPLE_ID}_hprc_polishing_QC.json'


###############################################################################
##                             write output files to csv                     ##
###############################################################################

cd /private/groups/hprc/polishing/batch5

## collect location of QC results
python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.polished.csv  \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs.json' \
      --submit_logs_directory /private/groups/hprc/polishing/batch5/slurm_logs
