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

# Create trio and hic input mappings

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

# Run HiC
sbatch \
     --job-name=HPRC-asm-batch9 \
     --array=[1] \
     -cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
          /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch9/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch9/HPRC_Assembly_s3Locs_Batch9-hic.csv \
     --input_json_path '/private/groups/hprc/assembly/batch9/hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json'

# Run Trio
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