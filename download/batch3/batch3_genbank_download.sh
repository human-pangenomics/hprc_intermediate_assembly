cd /private/groups/hprc/genbank_download

mkdir batch3 
cd batch3


###############################################################################
##                         Lookup Genbank Accessions                         ##
###############################################################################

## Get genome info file from NCBI Genome submission portal: genome-info-14704926.tsv

## lookup genbank accessions and organize table by sample
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/lookup_genbank_accessions.py \
    genome-info-14706183.tsv \
    batch3_genbank_accession_ids.csv 

cp batch3_genbank_accession_ids.csv batch3_genbank_accession_ids_original.csv

grep -vE '^HG02630|^HG00735' batch3_genbank_accession_ids_original.csv > batch3_genbank_accession_ids.csv

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
     --data_table ../batch3_genbank_accession_ids.csv \
     --field_mapping ../download_input_mapping.csv \
     --workflow_name ncbi_datasets_download_genome


cd ..
mkdir -p slurm_logs

## download assemblies from genbank and rename sequence IDs
sbatch \
     --job-name=HPRC-download_b3 \
     --array=[1-15] \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/ncbi_datasets_download_genome.wdl \
     --sample_csv batch3_genbank_accession_ids.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_ncbi_datasets_download_genome.json' 


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch3_genbank_accession_ids.csv \
    --output_data_table batch3_genbank_assembly.csv  \
    --json_location '{sample_id}_ncbi_datasets_download_genome_outputs.json'


###############################################################################
##                      Upload Assemblies To S3.                             ##
###############################################################################

cd /private/groups/hprc/genbank_download/batch3 


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
     --csv_file batch3_genbank_assembly.csv \
     --mapping_csv genbank_s3_upload_linking_map.csv


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    s3_upload \
    &>>batch3_s3.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################
