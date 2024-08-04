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

cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch7/hifiasm_input_jsons/hifiasm_input_mapping.csv

# Create input jsons for trio
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_Batch9-trio.csv \
     --field_mapping hifiasm_trio_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

# Create input jsons for hic
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_Batch9-hic.csv \
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
     --sample_csv /private/groups/hprc/assembly/batch9/HPRC_Assembly_s3Locs_Batch9-hic.csv \
     --input_json_path '/private/groups/hprc/assembly/batch9/hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json'



sbatch \
     --job-name=HPRC-asm-batch9-trio \
     --array=[1-5] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch9/HPRC_Assembly_s3Locs_Batch9-trio.csv \
     --input_json_path '/private/groups/hprc/assembly/batch9/hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'

###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch9

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch9_hic.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch9-hic_w_hifiasm.csv \
      --json_location '{sample_id}_hic_hifiasm_assembly_cutadapt_multistep_outputs.json'

###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch9
mkdir -p initial_qc
cd initial_qc

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch8_w_hifiasm.csv \
     --field_mapping ../hic_qc_input_mapping.csv \
     --workflow_name initial_qc

