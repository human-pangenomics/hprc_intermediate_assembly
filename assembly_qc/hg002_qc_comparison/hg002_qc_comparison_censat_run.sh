################################################################################
##                      Remove Extra Info From Assembly                       ##
################################################################################


cd /private/groups/hprc/qc_testing/hg002_qc_comparison

mkdir -p censat
cd censat 

mkdir input

aws s3 cp s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG002.hap1_for_genbank.fa.gz ./
aws s3 cp s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG002.hap2_for_genbank.fa.gz ./


gunzip -fc HG002.hap1_for_genbank.fa.gz \
    | awk '/^>/ {sub(/ .*/, "", $0)} {print}' \
    > input/HG002.hap1_for_genbank.fa

gunzip -fc HG002.hap2_for_genbank.fa.gz \
    | awk '/^>/ {sub(/ .*/, "", $0)} {print}' \
    > input/HG002.hap2_for_genbank.fa

################################################################################
##                      Test CenSat WDL: full data                            ##
################################################################################

## note which commit we are on
git -C /private/home/juklucas/github/alphaAnnotation log -1
# commit 35e53eb9bb3166e9c1409bec2a4101a9756e9c72 (HEAD -> main, origin/main, origin/HEAD)



cat <<EOF > censat_input_mapping.csv 
input,type,value
centromereAnnotation.fasta,scalar,\$input.asm
centromereAnnotation.rDNAhmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/rDNA1.0.hmm
centromereAnnotation.AS_hmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-HORs-hmmer3.4-071024.hmm
centromereAnnotation.AS_hmm_profile_SF,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-SFs-hmmer3.0.290621.hmm
centromereAnnotation.additionalRMModels,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/xy_apes_y_human_newmodels.embl
EOF


mkdir -p input_jsons
cd input_jsons

## create input jsons
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../hg002_censat.csv \
     --field_mapping ../censat_input_mapping.csv \
     --workflow_name censat

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=censat \
     --array=[1-2]%2 \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv hg002_censat.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table hg002_censat.csv \
    --output_data_table hg002_censat_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

mkdir s3_upload
cd s3_upload

awk -F',' 'NR==1 {print "sample_id,sample_hap," $3 "," substr($0, index($0, $4))} NR>1 {split($1, a, "_hap"); print a[1] "," $1 "," $3 "," substr($0, index($0, $4))}' \
    ../hg002_censat_outputs.csv  \
    > hg002_censat_outputs_sample_oriented.csv

cat <<EOF > censat_upload_linking_map.csv
column_name,destination
repeatMaskerTarGZ,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
rmOutFile,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
rmFinalMaskedFasta,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
rmRmskAlignBed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
rmRmskBed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
rmBed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/repeat_masker/
as_sf_bed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
as_hor_bed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
as_strand_bed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
as_hor_sf_bed,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
centromeres,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
cenSatStrand,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
cenSatAnnotations,upload/{sample_id}/assemblies/freeze_2/assembly_pipeline/ncbi_upload/annotation/censat/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file hg002_censat_outputs_sample_oriented.csv \
     --mapping_csv censat_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>hg002_censat_s3_upload.stderr

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/generate_s3_path.py \
    --csv_file hg002_censat_outputs_sample_oriented.csv \
    --mapping_csv censat_upload_linking_map.csv \
    --s3_base_path s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION




