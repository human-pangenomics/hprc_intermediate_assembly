
###############################################################################
##                             create input jsons                            ##
###############################################################################

cd /private/groups/hprc/assembly

rm -rf batch6

mkdir batch6
cd batch6/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/HPRC_Assembly_s3Locs_batch6.csv . 

mkdir hifiasm_input_jsons
cd hifiasm_input_jsons

cp /private/groups/hprc/hprc_intermediate_assembly/assembly/batch6/hifiasm_input_jsons/hifiasm_input_mapping.csv ./

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Assembly_s3Locs_batch6.csv \
     --field_mapping hifiasm_input_mapping.csv \
     --workflow_name trio_hifiasm_assembly_cutadapt_multistep

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

## on HPC...
cd /private/groups/hprc/assembly/batch6

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull
git -C /private/home/juklucas/github/hpp_production_workflows/ pull

mkdir slurm_logs

## second part of batch has higher coverage, so give more memory and start first
## had to remove commas in 40 & 42
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

## rerun failures
sbatch \
     --job-name=HPRC-asm-batch6 \
     --array=[5,21,29,40,42]  \
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

## still didn't run
# HG04160 21 childReadsHiFi malformed
# HG02717 40 remove trailing comma s3://human-pangenomics/submissions/B4B0B5DC-5FD5-42D5-8434-10DEF7D99E98--HPRC_DEEPCONSENSUS_v1pt2_2024_02_q20_re-run/HG02717/raw_data/PacBio_HiFi/deepconsensus/v1pt2/HG02717.m64136_220603_180611.dc.q20.fastq.gz
# HG03579 42 remove trailing comma s3://human-pangenomics/submissions/B4B0B5DC-5FD5-42D5-8434-10DEF7D99E98--HPRC_DEEPCONSENSUS_v1pt2_2024_02_q20_re-run/HG03579/raw_data/PacBio_HiFi/deepconsensus/v1pt2/HG03579.m64043_220607_102715.dc.q20.fastq.gz

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
     --array=[1-20,22-39,41]%20  \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
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


python3 << 'EOF'
import csv

# Function to find the column number with "filtQCStats" in the header
def find_column_index(header, column_name):
    for index, col in enumerate(header):
        if col.strip() == column_name:
            return index
    return -1

# Function to find rows without values in the specified column
def find_empty_rows(file_name, column_name):
    with open(file_name, newline='') as csvfile:
        reader = csv.reader(csvfile)
        header = next(reader)
        column_index = find_column_index(header, column_name)
        
        if column_index == -1:
            raise ValueError(f"Column '{column_name}' not found in the header.")
        
        empty_rows = []
        for row_number, row in enumerate(reader, start=2):  # start=2 to account for header row
            if not row[column_index].strip():
                empty_rows.append(row_number)
        
        return empty_rows

# Function to convert a list of row numbers to ranges
def convert_to_ranges(row_numbers):
    if not row_numbers:
        return []
    
    ranges = []
    start = end = row_numbers[0]
    
    for number in row_numbers[1:]:
        if number == end + 1:
            end = number
        else:
            ranges.append((start, end))
            start = end = number
    
    ranges.append((start, end))
    return ranges

# Main script execution
file_name = "HPRC_Assembly_s3Locs_batch6_w_hifiasm_w_QC.csv"
column_name = "filtQCStats"

empty_rows = find_empty_rows(file_name, column_name)
ranges = convert_to_ranges(empty_rows)

# Print ranges
for start, end in ranges:
    if start == end:
        print(start - 1) 
    else:
        print(f"{start - 1}-{end - 1}") 

EOF

## Missing QC...
# 1-18
# 20-21
# 40
# 42

## add one to ranges gives:
## 
## we know that 21, 40, 42 didn't finish assembly, so we can relaunch QC with:
## 1-18,20

cd /private/groups/hprc/assembly/batch6

sbatch \
     --job-name=HPRC-qc-batch6 \
     --array=[1-18,20]  \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/workflows/comparison_qc.wdl \
     --sample_csv HPRC_Assembly_s3Locs_batch6_w_hifiasm.csv \
     --input_json_path '../initial_qc/qc_input_jsons/${SAMPLE_ID}_initial_qc.json' \
     --toil_args '--restart'



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

