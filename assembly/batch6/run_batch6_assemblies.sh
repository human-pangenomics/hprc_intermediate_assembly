
###############################################################################
##                             create input jsons                            ##
###############################################################################

cd /private/groups/hprc/assembly

# rm -rf batch6

mkdir batch6
cd batch6/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/HPRC_Assembly_s3Locs_batch6.csv . 

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

cp /private/groups/hprc/assembly/batch3/hifiasm_input_mapping.csv ./

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch6.csv \
     --field_mapping hifiasm_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch6

## check that github repo is up to date
git -C /private/home/juklucas/github/hpp_production_workflows/ pull

mkdir slurm_logs

## second part of batch has higher coverage, so give more memory and start first
sbatch \
     --job-name=HPRC-asm-batch6 \
     --array=[25-42]%24  \
     --cpus-per-task=64 \
     --mem=650gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'  


sbatch \
     --job-name=HPRC-asm-batch6 \
     --array=[1-24]%24  \
     --cpus-per-task=64 \
     --mem=450gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'  

# ###############################################################################
# ##                         Update table with outputs                         ##
# ###############################################################################

cd /private/groups/hprc/assembly/batch6

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch6.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
      --json_location '{sample_id}_trio_hifiasm_assembly_cutadapt_multistep_outputs.json'


###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch6

mkdir -p initial_qc
cd initial_qc

cp /private/groups/hprc/assembly/batch3/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch6

mkdir qc_submit_logs


sbatch \
     --job-name=HPRC-qc-batch6 \
     --array=[1-42]%42  \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 



sbatch \
     --job-name=HPRC-qc-batch6 \
     --array=[2-17]  \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 

###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch6

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch6_extracted_qc_results.csv

## copy to github repo for notetaking
cp HPRC_Assembly_s3Locs_batch6_w*.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/

cp hifiasm_input_jsons/* \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/hifiasm_input_jsons/
  

# ## git add, commit, push
# cp -r \
#      initial_qc/ \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/

