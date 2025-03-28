cd /private/groups/hprc/genbank_download

mkdir batch2 
cd batch2

## two samples are not in this download set (yet)...
## HG02683: held onto because it has a RAD51 mutation that may make it's results 
## not biologically reasonable (we don't really know).

## HG02738: need to clean...
## HG02738#2#h2tg000012l  98268417  98228921..98231355  vector/etc-not_cleaned


###############################################################################
##                         Lookup Genbank Accessions                         ##
###############################################################################

## Get genome info file from NCBI Genome submission portal

## lookup genbank accessions and organize table by sample
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/lookup_genbank_accessions.py \
    genome-info-14703591.tsv \
    batch2_genbank_accession_ids.csv 

###############################################################################
##                         Download Genbank Version                          ##
###############################################################################


cat <<EOF > download_input_mapping.csv
input,type,value
ncbi_datasets_download_genome_wf.sample_name,scalar,\$input.sample_id
ncbi_datasets_download_genome_wf.genome_accession,scalar,\$input.paternal_genbank_accession
ncbi_datasets_download_genome_wf.haplotype_string,scalar,"pat"
ncbi_datasets_download_genome_wf.haplotype_int,scalar,"1"
ncbi_datasets_download_genome_wf.genome_accession_2,scalar,\$input.maternal_genbank_accession
ncbi_datasets_download_genome_wf.haplotype_string_2,scalar,"mat"
ncbi_datasets_download_genome_wf.haplotype_int_2,scalar,"2"
ncbi_datasets_download_genome_wf.output_tag,scalar,"hprc_r2_v1"
ncbi_datasets_download_genome_wf.reheader_fasta,scalar,true
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch2_genbank_accession_ids.csv \
     --field_mapping ../download_input_mapping.csv \
     --workflow_name ncbi_datasets_download_genome


cd ..
mkdir -p slurm_logs

## run assembly cleanup
sbatch \
     --job-name=HPRC-download_b2 \
     --array=[1-33] \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/ncbi_datasets_download_genome.wdl \
     --sample_csv batch2_genbank_accession_ids.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_ncbi_datasets_download_genome.json' 


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch2_genbank_accession_ids.csv \
    --output_data_table batch2_genbank_accession_table.csv  \
    --json_location '{sample_id}_ncbi_datasets_download_genome_outputs.json'


###############################################################################
##                      Upload Assemblies To S3.                             ##
###############################################################################

cd /private/groups/hprc/genbank_download/batch2

cat <<EOF > genbank_s3_upload_linking_map.csv
column_name,destination
genbank_fa_hap1_gz,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_gzi,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_fai,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_md5,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_gzi,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_fai,s3_upload/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_md5,s3_upload/{sample_id}/assemblies/freeze_2/
EOF

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch2_genbank_accession_table.csv \
     --mapping_csv genbank_s3_upload_linking_map.csv


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    s3_upload \
    &>>batch2_s3.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################
