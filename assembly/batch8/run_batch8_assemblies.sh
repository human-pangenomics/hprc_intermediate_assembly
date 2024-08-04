###############################################################################
##                             create input jsons                            ##
###############################################################################

## on HPC...
cd /private/groups/hprc/assembly

## check that github repo is up to date
# git -C /private/groups/hprc/hprc_intermediate_assembly pull
git clone git@github.com:human-pangenomics/hpp_production_workflows.git
git clone git@github.com:human-pangenomics/hprc_intermediate_assembly.git

## get sample sheet
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch8/HPRC_Assembly_s3Locs_batch8.csv ./

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

## get input mapping; make sure to include q-score cutoff!
# create hifiasm_hic_input_mapping.csv

# ```rmarkdown

# Review parameters with hifiasm_hic_input_mapping using womtools

# java -jar /private/groups/hprc/human-pangenomics/cromwell/womtool-54.jar \
#   inputs \
# 	/private/groups/hprc/assembly/batch8/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl  \
#   | grep -v "optional"


# ```


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_Batch8.csv \
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
     --job-name=HPRC-asm-batch8 \
     --array=[1-30] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch8/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch8/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch8/HPRC_Assembly_s3Locs_Batch8.csv \
     --input_json_path '/private/groups/hprc/assembly/batch8/hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json'

###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch8

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_Batch8.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
      --json_location '{sample_id}_hic_hifiasm_assembly_cutadapt_multistep_outputs.json'

###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch8
mkdir -p initial_qc
cd initial_qc


mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
     --field_mapping ../hic_qc_input_mapping.csv \
     --workflow_name initial_qc    


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch8

# mkdir qc_submit_logs

sbatch \
     --job-name=HPRC-qc-batch8 \
     --array=[1-30]%30 \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch8/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/groups/hprc/assembly/batch8/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
     --input_json_path '/private/groups/hprc/assembly/batch8/initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json'

###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch8

mkdir -p initial_qc
cd initial_qc

# NOTE: this depends on trio or hic
cp /private/groups/hprc/assembly/batch7/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    

###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch8

mkdir qc_submit_logs

sbatch \
     --job-name=HPRC-qc-batch8 \
     --array=[1-30]%30 \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch8/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/groups/hprc/assembly/batch8/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json'

###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch8

## collect location of QC results
python3 /private/groups/hprc/assembly/batch8/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch8_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch8_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch8_extracted_qc_results.csv