cd /private/groups/hprc/genbank_download/batch6

# HG01978   1   83  97  swapped
# HG01978   2   97  83  swapped
# HG02257   2   113 79  swapped
# HG02257   1   79  113 swapped
# HG03516   1   72  74  swapped
# HG03516   2   74  72  swapped

###############################################################################
##                         Lookup Genbank Accessions                         ##
###############################################################################

## move old (wrong) versions to avoid confusion with updated version
mv HG01978 HG01978_incorrect
mv HG02257 HG02257_incorrect
mv HG03516 HG03516_incorrect

head -n1 batch6_genbank_accession_ids.csv > batch6_genbank_accession_ids_fix_swap.csv
grep -E "HG01978|HG02257|HG03516" batch6_genbank_accession_ids.csv >> batch6_genbank_accession_ids_fix_swap.csv

cat batch6_genbank_accession_ids_fix_swap.csv
# sample_id,hap1_bioproject_accession,hap1_genome_acc,hap1_genbank_accession,hap1_hap_str,hap2_bioproject_accession,hap2_genome_acc,hap2_genbank_accession,hap2_hap_str
# HG01978,PRJNA726175,JAGYVR000000000,GCA_018472845.2,pat,PRJNA726176,JAGYVS000000000,GCA_018472865.2,mat
# HG02257,PRJNA723016,JAGYVH000000000,GCA_018466835.2,pat,PRJNA723017,JAGYVI000000000,GCA_018466845.2,mat
# HG03516,PRJNA725603,JAGYYS000000000,GCA_018469415.2,pat,PRJNA725604,JAGYYT000000000,GCA_018469425.2,mat

###############################################################################
##                         Download Genbank Version                          ##
###############################################################################


cat <<EOF > download_input_mapping_fix_swap.csv
input,type,value
ncbi_datasets_download_genome_wf.sample_name,scalar,\$input.sample_id
ncbi_datasets_download_genome_wf.genome_accession,scalar,\$input.hap2_genbank_accession
ncbi_datasets_download_genome_wf.haplotype_string,scalar,"\$input.hap1_hap_str"
ncbi_datasets_download_genome_wf.haplotype_int,scalar,"1"
ncbi_datasets_download_genome_wf.genome_accession_2,scalar,\$input.hap1_genbank_accession
ncbi_datasets_download_genome_wf.haplotype_string_2,scalar,"\$input.hap2_hap_str"
ncbi_datasets_download_genome_wf.haplotype_int_2,scalar,"2"
ncbi_datasets_download_genome_wf.output_tag,scalar,"hprc_r2_v1.1.0"
ncbi_datasets_download_genome_wf.reheader_fasta,scalar,true
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch6_genbank_accession_ids_fix_swap.csv \
     --field_mapping ../download_input_mapping_fix_swap.csv \
     --workflow_name ncbi_datasets_download_genome


cd ..
mkdir -p slurm_logs

## download assemblies from genbank and rename sequence IDs
sbatch \
     --job-name=HPRC-fix_batch6 \
     --array=[1-3] \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/ncbi_datasets_download_genome.wdl \
     --sample_csv batch6_genbank_accession_ids_fix_swap.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_ncbi_datasets_download_genome.json' 


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch6_genbank_accession_ids_fix_swap.csv \
    --output_data_table batch6_genbank_assembly_fix_swap.csv  \
    --json_location '{sample_id}_ncbi_datasets_download_genome_outputs.json'


###############################################################################
##                      Hide Old (Swapped Assemblies) In S3                  ##
###############################################################################

# HG01978   1   83  97  swapped
# HG01978   2   97  83  swapped
# HG02257   2   113 79  swapped
# HG02257   1   79  113 swapped
# HG03516   1   72  74  swapped
# HG03516   2   74  72  swapped

cat<< EOF > README.txt
Date: 09 Feb. 2025  

### Haplotype Swap Correction  

It was discovered that some assemblies were haplotype swapped. The issue affects only the post-GenBank (released) versions, while all assemblies in the assembly_pipeline area remain correct.  

To maintain records and intentionally break prior URIs included in assembly data tables, the old (incorrect) versions and their annotations have been moved to the haplotype_swapped folder.  

### Affected Versions & Samples  
The following samples were affected in versions 1.0 and 1.0.1:  
- HG01978  
- HG02257  
- HG03516  

New corrected assemblies are assigned **version v1.1.0  
EOF

## Move HG01978
aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01978/assemblies/freeze_2/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01978/assemblies/freeze_2/swapped_hap/ \
    --recursive --exclude "*" --include "HG01978_*"

aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01978/assemblies/freeze_2/annotation/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01978/assemblies/freeze_2/swapped_hap/annotation/ \
    --recursive

aws s3 cp README.txt s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01978/assemblies/freeze_2/swapped_hap/


## Move HG02257
aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/swapped_hap/ \
    --recursive --exclude "*" --include "HG02257_*"

aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/annotation/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/swapped_hap/annotation/ \
    --recursive

aws s3 cp README.txt s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/swapped_hap/


## Move HG03516
aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03516/assemblies/freeze_2/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03516/assemblies/freeze_2/swapped_hap/ \
    --recursive --exclude "*" --include "HG03516_*"

aws s3 mv \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03516/assemblies/freeze_2/annotation/ \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03516/assemblies/freeze_2/swapped_hap/annotation/ \
    --recursive

aws s3 cp README.txt s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03516/assemblies/freeze_2/swapped_hap/


###############################################################################
##                      Upload Assemblies To S3.                             ##
###############################################################################

cd /private/groups/hprc/genbank_download/batch6 


cat <<EOF > genbank_s3_upload_linking_map_swap_fixed.csv
column_name,destination
genbank_fa_hap1_gz,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_gzi,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_fai,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap1_gz_md5,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_gzi,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_fai,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
genbank_fa_hap2_gz_md5,s3_upload_swap_fixed/{sample_id}/assemblies/freeze_2/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch6_genbank_assembly_fix_swap.csv \
     --mapping_csv genbank_s3_upload_linking_map_swap_fixed.csv


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    s3_upload_swap_fixed \
    &>>batch6_s3.s3_upload_swap_fixed.stderr


###############################################################################
##                    Remove Annotations From GitHub Data Index              ##
###############################################################################

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/data_tables/annotation


censat/censat_centromeres_pre_release_v0.1.index.csv


grep -vE '^(HG01978|HG02257|HG03516)' \
    censat/censat_centromeres_pre_release_v0.1.index.csv \
    > censat/censat_centromeres_pre_release_v0.2.index.csv

grep -vE '^(HG01978|HG02257|HG03516)' \
    censat/censat_pre_release_v0.1.index.csv \
    > censat/censat_pre_release_v0.2.index.csv

rm censat/censat_centromeres_pre_release_v0.1.index.csv
rm censat/censat_pre_release_v0.1.index.csv

grep -vE '^(HG01978|HG02257|HG03516)' \
    liftoff/liftoff_pre_release_v0.1.index.csv \
    > liftoff/liftoff_pre_release_v0.2.index.csv

rm liftoff/liftoff_pre_release_v0.1.index.csv

grep -vE '^(HG01978|HG02257|HG03516)' \
    repeat_masker/repeat_masker_bed_pre_release_v0.1.index.csv \
    > repeat_masker/repeat_masker_bed_pre_release_v0.2.index.csv

grep -vE '^(HG01978|HG02257|HG03516)' \
    repeat_masker/repeat_masker_out_pre_release_v0.1.index.csv \
    > repeat_masker/repeat_masker_out_pre_release_v0.2.index.csv


rm repeat_masker/repeat_masker_bed_pre_release_v0.1.index.csv
rm repeat_masker/repeat_masker_out_pre_release_v0.1.index.csv


###############################################################################
##                                   DONE                                    ##
###############################################################################
