
cd /private/groups/hprc/genbank_upload/

mkdir -p batch5
cd batch5

###############################################################################
##                            Run Cleanup WDL                                ##
###############################################################################

cat <<EOF > assembly_cleanup_input_mapping.csv
input,type,value
assembly_cleanup_wf.sample_id,scalar,\$input.sample_id
assembly_cleanup_wf.hap1_fasta,scalar,\$input.polishedAsmHap1
assembly_cleanup_wf.hap2_fasta,scalar,\$input.polishedAsmHap2
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


## copy in polishing results
cp /private/groups/hprc/polishing/batch6/HPRC_Assembly_s3Locs_Batch5_w_hifiasm.polished.csv ./

## filter out failures (or samples who need attention)
grep -vE '^NA20799|^HG03458' \
    HPRC_Assembly_s3Locs_Batch5_w_hifiasm.polished.csv  \
    > hprc_int_asm_batch5_polished.csv

mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hprc_int_asm_batch5_polished.csv \
     --field_mapping ../assembly_cleanup_input_mapping.csv \
     --workflow_name assembly_cleanup

cd ..
mkdir -p slurm_logs

## run assembly cleanup
sbatch \
     --job-name=cleanup_b5 \
     --array=[1-12] \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/assembly_cleanup.wdl \
     --sample_csv hprc_int_asm_batch5_polished.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_assembly_cleanup.json' 

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table hprc_int_asm_batch5_polished.csv \
    --output_data_table batch5_genbank_upload_prep_outputs.csv  \
    --json_location '{sample_id}_assembly_cleanup_outputs.json'


###############################################################################
##                           Pull Assembly Cleanup Stats                     ##
###############################################################################

mkdir asm_cleanup_stats 
cd asm_cleanup_stats

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_asm_cleanup_stats.py \
    --input_csv ../batch5_genbank_upload_prep_outputs.csv \
    --output_prefix hprc_int_asm_batch5


###############################################################################
##                  Soft Link Assemblies To Upload Folder                    ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch5/

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_folder.py \
    --data_table_csv batch5_genbank_upload_prep_outputs.csv \
    --columns_to_link hap1_output_fasta_gz hap2_output_fasta_gz \
    --target_dir batch5_genbank_upload


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch5_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch5


###############################################################################
##                      Upload Assemblies To S3.                             ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch5

mkdir batch5_s3_upload
cd batch5_s3_upload

cat <<EOF > upload_linking_map.csv
column_name,destination
rawUnitigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
hap1ContigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
hap2ContigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
hap1FastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
hap2FastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
polishedAsmHap1,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
polishedAsmHap2,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
DeepPolisherVcf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
mitoHiFi_eval_vcf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
mitoHiFi_eval_bam,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
read_to_concatmito_paf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
mitoHiFi_output_tar,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
hap2_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
hap1_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
EOF

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file ../batch5_genbank_upload_prep_outputs.csv \
     --mapping_csv upload_linking_map.csv


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch5_s3_upload_pt1.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################