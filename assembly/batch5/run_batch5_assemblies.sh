
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...
cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch5/

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_Batch5.csv \
     --field_mapping hifiasm_hic_input_mapping.csv \
     --workflow_name hic_hifiasm_assembly_cutadapt_multistep

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mkdir assembly/batch5
cd assembly/batch5

cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/hifiasm_input_jsons/ ./
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/HPRC_Assembly_s3Locs_Batch5.csv ./

mkdir slurm_logs

sbatch \
     --job-name=HPRC-asm-batch5 \
     --array=[1-14]%14 \
     --cpus-per-task=64 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_Batch5.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json' 

# fixed HG03471 input json to deal with comma problem. Restart.
sbatch \
     --job-name=HPRC-asm-batch5 \
     --array=[14]%1 \
     --cpus-per-task=64 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_Batch5.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json' 

###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch5

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_Batch5.csv  \
      --output_data_table HPRC_Assembly_s3Locs_Batch5_w_hifiasm.csv \
      --json_location '{sample_id}_hic_hifiasm_assembly_cutadapt_multistep_outputs.json'


###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch5

mkdir -p initial_qc
cd initial_qc

../../batch4/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_Batch5_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch5

mkdir qc_submit_logs

sbatch \
     --job-name=HPRC-qc-batch5 \
     --array=[1-14]%14 \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_Batch5_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 


# ###############################################################################
# ##                     Update table with hifiasm qc outputs                  ##
# ###############################################################################

# cd /private/groups/hprc/assembly/batch5

# ## collect location of QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
#       --input_data_table HPRC_Assembly_s3Locs_Batch5_w_hifiasm.csv  \
#       --output_data_table HPRC_Assembly_s3Locs_Batch5_w_hifiasm_w_QC.csv  \
#       --json_location '{sample_id}_comparison_qc.json'

# ## extract QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
#      --qc_data_table HPRC_Assembly_s3Locs_Batch5_w_hifiasm_w_QC.csv \
#      --extract_column_name filtQCStats \
#      --output initial_qc/batch5_extracted_qc_results.csv

# ## copy to github repo for notetaking
# cp HPRC_Assembly_s3Locs_Batch5_w_hifiasm.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/

# cp HPRC_Assembly_s3Locs_Batch5_w_hifiasm_w_QC.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/     

# ## git add, commit, push
# cp -r \
#      initial_qc/ \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/

