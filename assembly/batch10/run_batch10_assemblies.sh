###############################################################################
##                             create input jsons                            ##
###############################################################################

## on HPC...
cd /private/groups/hprc/assembly
mkdir batch9-v0.1

## check that github repo is up to date
# git -C /private/groups/hprc/hprc_intermediate_assembly pull
git clone git@github.com:human-pangenomics/hpp_production_workflows.git
git clone git@github.com:human-pangenomics/hprc_intermediate_assembly.git


# on HPC...
cd /private/groups/hprc/assembly
mkdir batch10

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

cp /private/groups/hprc/assembly/batch9/hprc_intermediate_assembly/assembly/batch9/hifiasm_input_jsons/hifiasm_input_mapping.csv hifiasm_trio_input_mapping.csv

# ```rmarkdown
# Check inputs for hifiasm_trio_input_mapping.csv
# java -jar /private/groups/hprc/human-pangenomics/cromwell/womtool-54.jar \
#   inputs \
# 	/private/groups/hprc/assembly/batch10/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl  \
#   | grep -v "optional"
#   {
#   "trioHifiasmAssembly.paternalID": "String",
#   "trioHifiasmAssembly.childReadsHiFi": "Array[File]",
#   "trioHifiasmAssembly.paternalReadsILM": "Array[File]",
#   "trioHifiasmAssembly.maternalReadsILM": "Array[File]",
#   "trioHifiasmAssembly.childID": "String",
#   "trioHifiasmAssembly.maternalID": "String",
# }
# ```

# Create input jsons for trio
python3 /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch10_trio.csv \
     --field_mapping hifiasm_trio_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch10

## check again that github repo is up to date
git -C hprc_intermediate_assembly pull
git -C hpp_production_workflows pull

mkdir slurm_logs

sbatch \
     --job-name=HPRC+-asm-batch10-trio \
     --array=[1-18] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch10/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch10/HPRC_Assembly_s3Locs_batch10_trio.csv \
     --input_json_path '/private/groups/hprc/assembly/batch10/hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'

# Run HG005
sbatch \
     --job-name=HPRC+-asm-batch10-trio \
     --array=[18] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch10/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch10/HPRC_Assembly_s3Locs_batch10_trio.csv \
     --input_json_path '/private/groups/hprc/assembly/batch10/hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'

# Create s3Locs batch10, update input jsons, and run HG01109 and HG0HG00202
sbatch \
     --job-name=HPRC+-asm-batch10-trio \
     --array=[1-2] \
     --cpus-per-task=64 \
     --mem=430gb \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/assembly/batch10/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv /private/groups/hprc/assembly/batch10/HPRC_Assembly_s3Locs_batch10_trio_v2.csv \
     --input_json_path '/private/groups/hprc/assembly/batch10/hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'


###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch10

python3 /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch10_trio.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm.csv \
      --json_location '{sample_id}_trio_hifiasm_assembly_cutadapt_multistep_outputs.json'

# NOTE: Delete HG005 until debug

###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch10
mkdir -p initial_qc
cd initial_qc

cp /private/groups/hprc/assembly/batch9-v0.1/initial_qc/trio_qc_input_mapping.csv .

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm.csv \
     --field_mapping ../trio_qc_input_mapping.csv \
     --workflow_name initial_qc 

###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch10

mkdir qc_submit_logs 

# Note we need to include HG005
sbatch \
     --job-name=HPRC+-qc-trio \
     --array=[1-17] \
     --partition=high_priority \
     /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/groups/hprc/assembly/batch10/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json'

###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch10

# collect location of QC results
python3 /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'

# collect location of QC results
python3 /private/groups/hprc/assembly/batch10/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch10_trio_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch10_extracted_qc_trio_results.csv
