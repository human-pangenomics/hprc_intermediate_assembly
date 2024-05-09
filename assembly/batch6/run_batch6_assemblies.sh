
###############################################################################
##                             create input jsons                            ##
###############################################################################

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch6/

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

cp /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch3/hifiasm_input_mapping.csv ./

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch6.csv \
     --field_mapping hifiasm_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mkdir assembly/batch6
cd assembly/batch6

cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/hifiasm_input_jsons/ ./
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/HPRC_Assembly_s3Locs_batch6.csv ./

mkdir slurm_logs

sbatch \
     --job-name=HPRC-asm-batch6 \
     --array=[1-30]%10  \
     --cpus-per-task=64 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'  


# ###############################################################################
# ##                         Update table with outputs                         ##
# ###############################################################################

# cd /private/groups/hprc/assembly/batch6

# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
#       --input_data_table HPRC_Assembly_s3Locs_batch6.csv  \
#       --output_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
#       --json_location '{sample_id}_trio_hifiasm_assembly_cutadapt_multistep_outputs.json'


# ###############################################################################
# ##                           Create QC Input JSONs                           ##   
# ###############################################################################

# cd /private/groups/hprc/assembly/batch6

# mkdir -p initial_qc
# cd initial_qc

# cp ../batch3/initial_qc/qc_input_mapping.csv ./

# mkdir qc_input_jsons
# cd qc_input_jsons

# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
#      --data_table ../../HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
#      --field_mapping ../qc_input_mapping.csv \
#      --workflow_name initial_qc    


# ###############################################################################
# ##                               launch initial QC                           ##   
# ###############################################################################

# cd /private/groups/hprc/assembly/batch6

# mkdir qc_submit_logs

# sbatch \
#      --job-name=HPRC-qc-batch6 \
#      --array=[1-30]%30  \
#      --partition=high_priority \
#      /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
#      --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
#      --sample_csv HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
#      --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 


# ###############################################################################
# ##                     Update table with hifiasm qc outputs                  ##
# ###############################################################################

# cd /private/groups/hprc/assembly/batch6

# ## collect location of QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
#       --input_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv  \
#       --output_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv  \
#       --json_location '{sample_id}_comparison_qc.json'

# ## extract QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
#      --qc_data_table HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv \
#      --extract_column_name filtQCStats \
#      --output initial_qc/batch6_extracted_qc_results.csv

# ## copy to github repo for notetaking
# cp HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/

# cp HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/     

# ## git add, commit, push
# cp -r \
#      initial_qc/ \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/

