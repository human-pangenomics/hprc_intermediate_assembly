
cd /private/groups/hprc/genbank_upload/

mkdir -p batch12
cd batch12

###############################################################################
##                            Run Group By XY                                ##
###############################################################################

mkdir hic_group_xy
cd hic_group_xy

mkdir assemblies
cd assemblies

aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20827/verkko/technopole-hic/GM20827.assembly.haplotype1.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20827/verkko/technopole-hic/GM20827.assembly.haplotype2.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20762/verkko/technopole-hic/GM20762.assembly.haplotype1.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20762/verkko/technopole-hic/GM20762.assembly.haplotype2.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20806/verkko/technopole-hic/GM20806.assembly.haplotype1.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20806/verkko/technopole-hic/GM20806.assembly.haplotype2.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20503/verkko/technopole-hic/GM20503.assembly.haplotype1.fasta .
aws s3 cp s3://human-pangenomics/submissions/A83029E5-5D14-450F-A3DB-9BFF8598BDBE--TECHNOPOLE_ASSEMBLIES/GM20503/verkko/technopole-hic/GM20503.assembly.haplotype2.fasta .

cd ..

cat <<EOF > hic_group_xy_input_mapping.csv
input,type,value
hic_group_xy_wf.group_xy.hap1_gz,scalar,\$input.raw_asm_hap1
hic_group_xy_wf.group_xy.hap2_gz,scalar,\$input.raw_asm_hap2
hic_group_xy_wf.group_xy.childID,scalar,\$input.sample_id
hic_group_xy_wf.group_xy.isMaleSample,scalar,\$input.isMaleSample
hic_group_xy_wf.group_xy.chrY_no_par_yak,scalar,/private/groups/hprc/ref_files/yak/chrY-no-par.yak
hic_group_xy_wf.group_xy.chrX_no_par_yak,scalar,/private/groups/hprc/ref_files/yak/chrX-no-par.yak
hic_group_xy_wf.group_xy.par_yak,scalar,/private/groups/hprc/ref_files/yak/par.yak
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hprc_int_asm_batch12_technopole.csv \
     --field_mapping ../hic_group_xy_input_mapping.csv \
     --workflow_name hic_group_xy

cd ..
mkdir -p slurm_logs

## run group by XY (yak)
sbatch \
     --job-name=groupbyxy_batch12 \
     --array=[1-4] \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/hic_group_xy.wdl \
     --sample_csv hprc_int_asm_batch12_technopole.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_hic_group_xy.json' 

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table hprc_int_asm_batch12_technopole.csv \
    --output_data_table hprc_int_asm_batch12_technopole_grouped.csv  \
    --json_location '{sample_id}_hic_group_xy_outputs.json'


###############################################################################
##                            Run Cleanup WDL                                ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12

cp hic_group_xy/hprc_int_asm_batch12_technopole_grouped.csv ./

cat <<EOF > assembly_cleanup_input_mapping.csv
input,type,value
assembly_cleanup_wf.sample_id,scalar,\$input.sample_id
assembly_cleanup_wf.hap1_fasta,scalar,\$input.outputHap1FastaGz
assembly_cleanup_wf.hap2_fasta,scalar,\$input.outputHap2FastaGz
assembly_cleanup_wf.hifi_reads,array,\$input.hifi
assembly_cleanup_wf.seq_info,scalar,/private/groups/hprc/ref_files/fcs/all.seq_info.tsv.gz
assembly_cleanup_wf.blast_div,scalar,/private/groups/hprc/ref_files/fcs/all.blast_div.tsv.gz
assembly_cleanup_wf.manifest,scalar,/private/groups/hprc/ref_files/fcs/all.manifest
assembly_cleanup_wf.taxa,scalar,/private/groups/hprc/ref_files/fcs/all.taxa.tsv
assembly_cleanup_wf.metaJSON,scalar,/private/groups/hprc/ref_files/fcs/all.meta.jsonl
assembly_cleanup_wf.GXS,scalar,/private/groups/hprc/ref_files/fcs/all.gxs
assembly_cleanup_wf.GXI,scalar,/private/groups/hprc/ref_files/fcs/all.gxi
assembly_cleanup_wf.related_mito_fasta,scalar,/private/groups/hprc/ref_files/mito/rcrs_reference/NC_012920.1.fasta
assembly_cleanup_wf.related_mito_genbank,scalar,/private/groups/hprc/ref_files/mito/rcrs_reference/NC_012920.1.gb
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hprc_int_asm_batch12_technopole_grouped.csv \
     --field_mapping ../assembly_cleanup_input_mapping.csv \
     --workflow_name assembly_cleanup

cd ..
mkdir -p slurm_logs

## run assembly cleanup
sbatch \
     --job-name=cleanup_batch12 \
     --array=[1-4] \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/assembly_cleanup.wdl \
     --sample_csv hprc_int_asm_batch12_technopole_grouped.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_assembly_cleanup.json' 

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table hprc_int_asm_batch12_technopole_grouped.csv \
    --output_data_table hprc_int_asm_batch12_technopole_outputs.csv  \
    --json_location '{sample_id}_assembly_cleanup_outputs.json'


###############################################################################
##                           Pull Assembly Cleanup Stats                     ##
###############################################################################

mkdir asm_cleanup_stats 
cd asm_cleanup_stats

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_asm_cleanup_stats.py \
    --input_csv ../hprc_int_asm_batch12_technopole_outputs.csv \
    --output_prefix hprc_int_asm_batch12

cat hprc_int_asm_batch12_fcs_adapter_results_aggregated.csv
# file_name,accession,length,action,range,name
# NA20827_hap1.fcs_adaptor_report.txt,,,,,
# NA20762_hap1.fcs_adaptor_report.txt,haplotype1-0000023,87187521,ACTION_TRIM,71247753..71247819,CONTAMINATION_SOURCE_TYPE_ADAPTOR:NGB01097.1:Oxford Nanopore Technologies Rapid Adapter RAP
# NA20806_hap1.fcs_adaptor_report.txt,haplotype1-0000027,72459230,ACTION_TRIM,"72459054..72459103,72459160..72459230",CONTAMINATION_SOURCE_TYPE_ADAPTOR:NGB01097.1:Oxford Nanopore Technologies Rapid Adapter RAP
# NA20503_hap1.fcs_adaptor_report.txt,,,,,
# NA20827_hap2.fcs_adaptor_report.txt,,,,,
# NA20762_hap2.fcs_adaptor_report.txt,,,,,
# NA20806_hap2.fcs_adaptor_report.txt,,,,,
# NA20503_hap2.fcs_adaptor_report.txt,haplotype2-0000087,198688,ACTION_TRIM,198664..198688,CONTAMINATION_SOURCE_TYPE_ADAPTOR:NGB01097.1:Oxford Nanopore Technologies Rapid Adapter RAP


###############################################################################
##                           Check For Misjoins                              ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12/

mkdir misjoinCheck
cd misjoinCheck


cat << EOF > misjoin_input_mapping.csv
input,type,value
misjoinCheck.ref_centromere_bed,scalar,/private/groups/hprc/qc_testing/misjoin/heng_regions.bed
misjoinCheck.ref_fasta,scalar,/private/groups/hprc/ref_files/chm13/chm13v2.0.fa.gz
misjoinCheck.name,scalar,\$input.sample_id
misjoinCheck.asm_fasta,scalar,\$input.asm
EOF

cp ../hprc_int_asm_batch12_technopole_outputs.csv ./hprc_int_asm_batch12_technopole_misjoin_check.csv
## modify table by hand to have hap2_output_fasta_gz & hap1_output_fasta_gz as 
## asm column (and covert wide to long)

mkdir -p input_jsons 
cd input_jsons


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hprc_int_asm_batch12_technopole_misjoin_check.csv \
     --field_mapping ../misjoin_input_mapping.csv \
     --workflow_name misjoin

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=HPRC-misjoin_all \
     --array=[1-8]  \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/QC/wdl/tasks/misjoinCheck.wdl \
     --sample_csv hprc_int_asm_batch12_technopole_misjoin_check.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_misjoin.json'


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table hprc_int_asm_batch12_technopole_misjoin_check.csv \
      --output_data_table hprc_int_asm_batch12_technopole_misjoin_check_w_results.csv \
      --json_location '{sample_id}_misjoinCheck_outputs.json'



cat << 'EOF' > extract_misjoins.py
import csv
import os

# Path to the CSV file
csv_file_path = 'hprc_int_asm_batch12_technopole_misjoin_check_w_results.csv'

# Path to the output file
output_file_path = 'misjoins.txt'

# Function to extract lines starting with 'J' from the given file and add sample_id
def extract_j_lines(file_path, sample_id):
    j_lines = []
    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith('J'):
                j_lines.append(f"{sample_id}\t{line}")
    return j_lines

# Read the CSV file and process each misjoinSummary path
with open(csv_file_path, 'r') as csv_file, open(output_file_path, 'w') as output_file:
    reader = csv.DictReader(csv_file)
    for row in reader:
        sample_id = row['sample_id']
        misjoin_summary_path = row['misjoinSummary']
        if os.path.exists(misjoin_summary_path):
            j_lines = extract_j_lines(misjoin_summary_path, sample_id)
            output_file.writelines(j_lines)
        else:
            print(f"File not found: {misjoin_summary_path}")

print(f"Extraction complete. Check the output file: {output_file_path}")
EOF

python3 extract_misjoins.py

cat misjoins.txt



###############################################################################
##                  Soft Link Assemblies To Upload Folder                    ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12/

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_folder.py \
    --data_table_csv hprc_int_asm_batch12_technopole_outputs.csv \
    --columns_to_link hap1_output_fasta_gz hap2_output_fasta_gz \
    --target_dir batch12_genbank_upload


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch12_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch12


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12

mkdir batch12_s3_upload
cd batch12_s3_upload


cat <<EOF > upload_linking_map.csv
column_name,destination
raw_asm_hap1,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
raw_asm_hap2,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
outputHap1FastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/groupbyxy
outputHap2FastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/groupbyxy
mitoHiFi_eval_vcf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
mitoHiFi_eval_bam,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
read_to_concatmito_paf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
mitoHiFi_output_tar,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
hap2_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
hap1_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
EOF




python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file ../hprc_int_asm_batch12_technopole_outputs.csv \
     --mapping_csv upload_linking_map.csv


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch12_s3_upload_pt1.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################


