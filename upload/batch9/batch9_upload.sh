
cd /private/groups/hprc/genbank_upload/

mkdir -p batch9
cd batch9

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
cp /private/groups/hprc/polishing/batch10/hprc_polishing_QC_k31/HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.csv ./

## filter out failures (or samples who need attention)
# grep -vE '^HG00867' \
## nothing to filter this time (it's a small batch)
cat \
    HPRC_Assembly_s3Locs_batch9_trio_w_hifiasm_w_QC_hic.polished.csv  \
    > hprc_int_asm_batch9_polished.csv

mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hprc_int_asm_batch9_polished.csv \
     --field_mapping ../assembly_cleanup_input_mapping.csv \
     --workflow_name assembly_cleanup

cd ..
mkdir -p slurm_logs

## run assembly cleanup
sbatch \
     --job-name=cleanup_batch9 \
     --array=[1-5] \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/assembly_cleanup.wdl \
     --sample_csv hprc_int_asm_batch9_polished.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_assembly_cleanup.json' 

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table hprc_int_asm_batch9_polished.csv \
    --output_data_table batch9_genbank_upload_prep_outputs.csv  \
    --json_location '{sample_id}_assembly_cleanup_outputs.json'

###############################################################################
##                           Pull Assembly Cleanup Stats                     ##
###############################################################################

mkdir asm_cleanup_stats 
cd asm_cleanup_stats

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_asm_cleanup_stats.py \
    --input_csv ../batch9_genbank_upload_prep_outputs.csv \
    --output_prefix hprc_int_asm_batch9


###############################################################################
##                  Soft Link Assemblies To Upload Folder                    ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch9/

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_folder.py \
    --data_table_csv batch9_genbank_upload_prep_outputs.csv \
    --columns_to_link hap1_output_fasta_gz hap2_output_fasta_gz \
    --target_dir batch9_genbank_upload


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch9_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch9


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

# cat <<EOF > upload_linking_map.csv
# column_name,destination
# rawUnitigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
# maternalContigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
# paternalContigGfaTarGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
# maternalFastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
# paternalFastaGz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/raw
# polishedGQFilterAsmHap1,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
# polishedGQFilterAsmHap2,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
# DeepPolisherFilteredVcf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/deeppolisher
# mitoHiFi_eval_vcf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
# mitoHiFi_eval_bam,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
# read_to_concatmito_paf,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
# mitoHiFi_output_tar,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/mitohifi
# hap2_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
# hap1_output_fasta_gz,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
# EOF


# python3 link_to_subfolder.py \
#      --csv_file ../batch2_genbank_upload_prep_outputs.csv \
#      --mapping_csv upload_linking_map.csv

###############################################################################
##                                   DONE                                    ##
###############################################################################


