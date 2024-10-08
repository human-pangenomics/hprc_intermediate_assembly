###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/github_repos/hprc_intermediate_assembly/polishing/batch10/hprc_polishing_QC_k21/hprc_polishing_QC_input_jsons

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing/batch10

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir -p hprc_polishing_QC_k21
cd hprc_polishing_QC_k21

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch10/hprc_polishing_QC_k21/* ./

mkdir -p slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

# submit job
sbatch \
     --job-name=hprc-polishing_QC_k21-batch10 \
     --array=[4]%5 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --mem=400gb \
     --mail-type=FAIL,END \
     --mail-user=mmastora@ucsc.edu \
     --exclude=phoenix-[09,10,22,23,24,18] \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_polishing_QC.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.csv \
     --input_json_path '../hprc_polishing_QC_input_jsons/${SAMPLE_ID}_hprc_polishing_QC.json'

###############################################################################
##                             write output files to csv                     ##
###############################################################################

cd /private/groups/hprc/polishing/batch10/hprc_polishing_QC_k21

## collect location of QC results
python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.csv \
      --output_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.k21QC.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json'


ls | grep "HG" | while read line ; do echo $line ; cat $line/analysis/hprc_polishing_QC_outputs/${line}.polishing.QC.csv  ; done >> all_samples_batch8_k21.csv
ls | grep "NA" | while read line ; do echo $line ; cat $line/analysis/hprc_polishing_QC_outputs/${line}.polishing.QC.csv  ; done >> all_samples_batch8_k21.csv
