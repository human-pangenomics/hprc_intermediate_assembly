
###############################################################################
##                             create input jsons                            ##
###############################################################################

cd /private/groups/hprc/assembly

mkdir batch7
cd batch7/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch7/HPRC_Assembly_s3Locs_batch7.csv . 

## separate trio and hic samples...
sed -n '1p;12p;13p' HPRC_Assembly_s3Locs_batch7.csv \
    > HPRC_Assembly_s3Locs_batch7_hic.csv
    
sed '12d;13d' HPRC_Assembly_s3Locs_batch7.csv \
    > HPRC_Assembly_s3Locs_batch7_trio.csv


mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch5/hifiasm_input_jsons/hifiasm_hic_input_mapping.csv ./
cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/hifiasm_input_jsons/hifiasm_input_mapping.csv ./

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch7_trio.csv \
     --field_mapping hifiasm_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch7_hic.csv \
     --field_mapping hifiasm_hic_input_mapping.csv \
     --workflow_name hic_hifiasm_assembly_cutadapt_multistep


###############################################################################
##                                 launch assemblies                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch7

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull
git -C /private/home/juklucas/github/hpp_production_workflows/ pull

mkdir slurm_logs

## trio samples
sbatch \
     --job-name=HPRC-asm-batch7 \
     --array=[1-10]  \
     --cpus-per-task=64 \
     --mem=450gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch7_trio.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'  


sbatch \
     --job-name=HPRC-asm-batch7 \
     --array=[1-10]  \
     --cpus-per-task=64 \
     --mem=450gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/trio_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch7_trio.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_trio_hifiasm_assembly_cutadapt_multistep.json'  


sbatch \
     --job-name=HPRC-asm-batch7-hic \
     --array=[1-2] \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/hic_hifiasm_assembly_cutadapt_multistep.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch7_hic.csv \
     --input_json_path '../hifiasm_input_jsons/${SAMPLE_ID}_hic_hifiasm_assembly_cutadapt_multistep.json' 


# ###############################################################################
# ##                         Update table with outputs                         ##
# ###############################################################################

cd /private/groups/hprc/assembly/batch7

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch7_trio.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm.csv \
      --json_location '{sample_id}_trio_hifiasm_assembly_cutadapt_multistep_outputs.json'

###############################################################################
##                           Create QC Input JSONs                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch7

mkdir -p initial_qc
cd initial_qc

cp /private/groups/hprc/assembly/batch6/initial_qc/qc_input_mapping.csv ./

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch7

mkdir qc_submit_logs

sbatch \
     --job-name=HPRC-qc-batch7 \
     --array=[1-7,9,10]  \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' 


###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

cd /private/groups/hprc/assembly/batch7

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm.csv  \
      --output_data_table HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_comparison_qc_outputs.json'


## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc.py \
     --qc_data_table HPRC_Assembly_s3Locs_batch7_trio_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch7_extracted_qc_trio_results.csv

## copy to github repo for notetaking
cp HPRC_Assembly_s3Locs_batch7_w*.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch7/

cp hifiasm_input_jsons/* \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch7/hifiasm_input_jsons/
  

# ## git add, commit, push
# cp -r \
#      initial_qc/ \
#      /private/groups/hprc/hprc_intermediate_assembly/assembly/batch7/

