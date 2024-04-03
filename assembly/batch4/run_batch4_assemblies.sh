
## I ran Batch4 before, but I had to manually rerun the last step.
## Just to be careful, I want to rerun everything from scratch.

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mv assembly/batch4 assembly/batch4_old

mkdir assembly/batch4
cd assembly/batch4

mv ../batch4_old ./

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/hifiasm_input_jsons/ ./
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/HPRC_Intermediate_Assembly_s3Locs_Batch4.csv ./

mkdir slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

sbatch \
     --job-name=HPRC-asm-batch4 \
     --array=[1-24]%24 \
     --cpus-per-task=64 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_hifiasm.json' 

## redo job 5 because it got stuck on a failing node  
sbatch \
     --job-name=HPRC-asm-batch4 \
     --array=[5]%1 \
     --cpus-per-task=64 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_hifiasm.json' 

###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch4

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
      --json_location '{sample_id}_hic_hifiasm_assembly_cutadapt_multistep_outputs.json'


###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch4

mkdir -p initial_qc
cd initial_qc

cp ../batch4_old/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch4

mkdir qc_submit_logs

sbatch \
     --job-name=HPRC-qc-batch4 \
     --array=[1-24]%24 \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 


###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch4

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
     --qc_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch4_extracted_qc_results.csv

## copy to github repo for notetaking
cp HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/

cp HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/     

mv blah.csv initial_qc/t2t_counts.csv

cp -r \
     initial_qc/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/

## git add, commit, push
