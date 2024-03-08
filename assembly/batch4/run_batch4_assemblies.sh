
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
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/launch_hprc_array_local.sh ./

mkdir slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

## Test local array script: 2607801
sbatch \
     --job-name=HPRC-asm-batch4 \
     --array=[1]%1 \
     --cpus-per-task=64 \
     --mem=400gb \
     launch_hprc_array_local.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch4.csv \
     /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     '../hifiasm_input_jsons/${sample_id}_hifiasm.json' 

  
# ###############################################################################
# ##                         Update table with outputs                         ##
# ###############################################################################

# cd /private/groups/hprc/assembly/batch4

# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
#       --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4.csv  \
#       --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
#       --json_location '{sample_id}_hifiasm_outputs.json'

# cp HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/


# ###############################################################################
# ##                               launch initial QC                           ##   
# ###############################################################################

# cd /private/groups/hprc/assembly/batch4

# mkdir qc_submit_logs

# sbatch \
#     --array=[1-24]%24 \
#     initial_qc/launch_initial_qc_array.sh \
#     HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv 


# ###############################################################################
# ##                     Update table with hifiasm qc outputs                  ##
# ###############################################################################

# ## collect location of QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
#       --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4.csv  \
#       --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv  \
#       --json_location '{sample_id}_hifiasm_qc_outputs.json'

# ## extract QC results
# python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
#      --qc_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
#      --extract_column_name filtQCStats \
#      --output initial_qc/batch4_extracted_qc_results.csv

# cp \
#      HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch3/HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv

# ## add/commit/push to github (hprc_intermediate_assembly)

