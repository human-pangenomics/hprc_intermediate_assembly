###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch7/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv \
     --field_mapping ../hprc_DeepPolisher_input_mapping.csv \
     --workflow_name hprc_DeepPolisher

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

mkdir -p batch7
cd batch7

cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch7/* ./

mkdir -p slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

# submit job. skip slurm # 3,10
sbatch \
     --job-name=hprc-DeepPolisher-batch7 \
     --array=[15,20,26,41]%4 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --mem=400gb \
     --mail-type=FAIL,END \
     --exclude=phoenix-[09,10,22,23,24] \
     --ntasks-per-node=2 \
     --mail-user=mmastora@ucsc.edu \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv \
     --input_json_path '../hprc_DeepPolisher_input_jsons/${SAMPLE_ID}_hprc_DeepPolisher.json'

###############################################################################
##                             write output files to csv                     ##
###############################################################################

cd /private/groups/hprc/polishing/batch7

## collect location of QC results
python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.polished.csv  \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs.json'
