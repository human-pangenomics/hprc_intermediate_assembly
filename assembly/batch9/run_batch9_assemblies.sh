###############################################################################
##                             create input jsons                            ##
###############################################################################

## on HPC...
cd /private/groups/hprc/assembly
mkdir batch9

## check that github repo is up to date
# git -C /private/groups/hprc/hprc_intermediate_assembly pull
git clone git@github.com:human-pangenomics/hpp_production_workflows.git
git clone git@github.com:human-pangenomics/hprc_intermediate_assembly.git

## get sample sheet
# cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch/HPRC_Assembly_s3Locs_Batch8.csv ./

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons


# Check input mappings

cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch7/hifiasm_input_jsons/hifiasm_input_mapping.csv hifiasm_trio_input_mapping.csv

# ```rmarkdown
# Check inputs for hifiasm_trio_input_mapping.csv
# java -jar /private/groups/hprc/human-pangenomics/cromwell/womtool-54.jar \
#   inputs \
# 	/private/groups/hprc/assembly/batch8/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl  \
#   | grep -v "optional"
# ```

# Create input jsons for trio
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch9_trio.csv \
     --field_mapping hifiasm_trio_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep


cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch7/hifiasm_input_jsons/hifiasm_hic_input_mapping.csv

# ```rmarkdown
# Check inputs for hifiasm_hic_input_mapping.csv
# java -jar /private/groups/hprc/human-pangenomics/cromwell/womtool-54.jar \
#   inputs \
# 	/private/groups/hprc/assembly/batch8/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl  \
#   | grep -v "optional"
# ```


# Create input jsons for hic
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch9_hic.csv \
     --field_mapping hifiasm_hic_input_mapping.csv \
     --workflow_name hic_hifiasm_assembly_cutadapt_multistep


###############################################################################
##                                 launch assemblies                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch8

## check again that github repo is up to date
git -C hprc_intermediate_assembly pull
git -C hpp_production_workflows pull

mkdir slurm_logs

sbatch \
     --job-name=HPRC-asm-batch9 \
     --array=[1] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch9/HPRC_Assembly_s3Locs_batch9_hic.csv \
     --input_json_path '/private/groups/hprc/assembly/batch9/hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json'



sbatch \
     --job-name=HPRC-asm-batch9-trio \
     --array=[1-4] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch9/HPRC_Assembly_s3Locs_batch9_trio.csv \
     --input_json_path '/private/groups/hprc/assembly/batch9/hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'

###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch9

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch9_hic.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm.csv \
      --json_location '{sample_id}_hic_hifiasm_assembly_cutadapt_multistep_outputs.json'


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch9_trio.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm.csv \
      --json_location '{sample_id}_trio_hifiasm_assembly_cutadapt_multistep_outputs.json'


###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch9
mkdir -p initial_qc
cd initial_qc

mkdir qc_input_jsons
cd qc_input_jsons

cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch7/initial_qc/hic_qc_input_mapping.csv
cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch7/initial_qc/qc_input_mapping.csv trio_qc_input_mapping.csv

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm.csv \
     --field_mapping ../hic_qc_input_mapping.csv \
     --workflow_name initial_qc   

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm.csv \
     --field_mapping ../trio_qc_input_mapping.csv \
     --workflow_name initial_qc  

###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch9

mkdir qc_submit_logs # note this is not working

# Run hic
sbatch \
     --job-name=HPRC-qc-batch9-hic \
     --array=[1] \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json'

# Run trio
sbatch \
     --job-name=HPRC-qc-batch9-trio \
     --array=[1-4] \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json'

###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch9

# collect location of QC results
python3 /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'

# collect location of QC results
python3 /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch9_extracted_qc_trio_results.csv

# hic
python3 /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
     --input_data_table HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm.csv  \
     --output_data_table HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm_w_QC.csv  \
     --json_location '{sample_id}_comparison_qc_outputs.json'

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch9_hic_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch9_extracted_qc_hic_results.csv