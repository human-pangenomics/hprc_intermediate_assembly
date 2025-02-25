
cd /private/groups/hprc/qc/

mkdir -p batch3/censat
cd batch3/censat

###############################################################################
##                             Run Censat WDL                                ##
###############################################################################

## get assembly table and create haplotype-specific sample_ids
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.6.1.index.csv

awk -F',' 'BEGIN {OFS=","} NR==1 {$1="sample_name"; print "sample_id",$0; next} {print $1"_hap"$2,$0}' \
    assemblies_pre_release_v0.6.1.index.csv \
    > assemblies_pre_release_v0.6.1_hap_formatted.index.csv


## get samples that have been run through censat
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/annotation/censat/censat_pre_release_v0.2.index.csv

## and remove them to create index file
awk -F',' 'NR==FNR {samples[$1]; next} !($2 in samples)' \
    censat_pre_release_v0.2.index.csv \
    assemblies_pre_release_v0.6.1_hap_formatted.index.csv \
    | grep -vE "HG002|CHM13|GRCh38" \
    > batch3_censat.csv


cat <<EOF > censat_input_mapping.csv 
input,type,value
centromereAnnotation.fasta,scalar,\$input.assembly
centromereAnnotation.rDNAhmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/rDNA1.0.hmm
centromereAnnotation.AS_hmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-HORs-hmmer3.4-071024.hmm
centromereAnnotation.AS_hmm_profile_SF,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-SFs-hmmer3.0.290621.hmm
centromereAnnotation.additionalRMModels,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/xy_apes_y_human_newmodels.embl
EOF


## check that github repo is up to date
git -C /private/home/juklucas/github/alphaAnnotation pull

## check which commit we are on:
git -C /private/home/juklucas/github/alphaAnnotation log -1
# commit 44a3d7e8ccae82cce146760b9dcad64502973793 (HEAD -> main, origin/main, origin/HEAD)

mkdir input_jsons
cd input_jsons

## create input jsons
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch3_censat.csv \
     --field_mapping ../censat_input_mapping.csv \
     --workflow_name censat

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=censat \
     --array=[1-80]%80 \
     --cpus-per-task=64 \
     --threads-per-core=2 \
     --mem=400gb \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch3_censat.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch3_censat.csv \
    --output_data_table batch3_censat_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'


###############################################################################
##                          Manual Fix For One Sample                        ##
###############################################################################

# HG02027_hap1: too many contigs for last step :(

mkdir -p manual/HG02027_hap1

cd manual/HG02027_hap1

aws s3 cp \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02027/assemblies/freeze_2/HG02027_pat_hprc_r2_v1.0.1.fa.gz \
    ./


## split into two assemblies
zcat HG02027_pat_hprc_r2_v1.0.1.fa.gz \
    | awk 'BEGIN {RS=">"; ORS=""} NR>1 {print ">"$0 > (NR%2 ? "HG02027_pat_hprc_r2_v1.0.1_pt1.fa" : "HG02027_pat_hprc_r2_v1.0.1_pt2.fa")}'

## check that nothing is lost...
zcat HG02027_pat_hprc_r2_v1.0.1.fa.gz | awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}'
# Total Bases: 2965356762
# Total Contigs: 205

cat HG02027_pat_hprc_r2_v1.0.1_pt1.fa | awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}'
# Total Bases: 1321393352
# Total Contigs: 102

cat HG02027_pat_hprc_r2_v1.0.1_pt2.fa | awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}'
# Total Bases: 1643963410
# Total Contigs: 103

## looks good

## make data table by hand
head -n1 ../../batch3_censat.csv > batch3_censat_manual.csv

cat batch3_censat_manual.csv 
# sample_id,sample_name,haplotype,phasing,assembly_method,assembly_method_version,assembly_date,assembly_name,source,genbank_accession,assembly_md5,assembly_fai,assembly_gzi,assembly
# HG02027_hap1_pt1,,,,,,,,,,,,,/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_pat_hprc_r2_v1.0.1_pt1.fa
# HG02027_hap1_pt2,,,,,,,,,,,,,/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_pat_hprc_r2_v1.0.1_pt2.fa

mkdir input_jsons
cd input_jsons

## create input jsons
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch3_censat_manual.csv  \
     --field_mapping ../../../censat_input_mapping.csv \
     --workflow_name censat


cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=censat \
     --array=[1-2]%2 \
     --cpus-per-task=128 \
     --threads-per-core=2 \
     --mem=800gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch3_censat_manual.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch3_censat_manual.csv \
    --output_data_table batch3_censat_manual_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'


###############################################################################
##                        Combine Outputs From Manual Fix                    ##
###############################################################################

cd /private/groups/hprc/qc/batch3/censat/s3_upload

mkdir -p upload/HG02027/assemblies/freeze_2/annotation/censat
mkdir -p upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/

# Combine bed files in a for loop
for suffix in \
    cenSat \
    SatelliteStrand \
    active.centromeres \
    as_hor_sf \
    as_strand \
    as_hor \
    as_sf \
    RepeatMasker.rmsk \
    RepeatMasker \
    RepeatMasker.rmskAlign
do
  # Point to the pt1 and pt2 files
  pt1="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt1/analysis/centromereAnnotation_outputs/4084a3cc-eec5-45ce-b48f-1b24e2118700/HG02027_pat_hprc_r2_v1.0.1_pt1.${suffix}.bed"
  pt2="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt2/analysis/centromereAnnotation_outputs/ea813b5a-7484-4405-a65d-81424326c81e/HG02027_pat_hprc_r2_v1.0.1_pt2.${suffix}.bed"

  # Construct the output filename by stripping "_pt1" or "_pt2"
  # from HG02027_pat_hprc_r2_v1.0.1_pt1.${suffix}.bed => HG02027_pat_hprc_r2_v1.0.1.${suffix}.bed
  output="upload/HG02027/assemblies/freeze_2/annotation/censat/HG02027_pat_hprc_r2_v1.0.1.${suffix}.bed"

  # Merge and sort
  cat "${pt1}" "${pt2}" \
    | sort -k1,1 -k2,2n \
    > "${output}"
done

cp upload/HG02027/assemblies/freeze_2/annotation/censat/*RepeatMasker* upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/
rm upload/HG02027/assemblies/freeze_2/annotation/censat/*RepeatMasker*

## combine out files
out1="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt1/analysis/centromereAnnotation_outputs/4084a3cc-eec5-45ce-b48f-1b24e2118700/HG02027_pat_hprc_r2_v1.0.1_pt1.RepeatMasker.out"
out2="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt2/analysis/centromereAnnotation_outputs/ea813b5a-7484-4405-a65d-81424326c81e/HG02027_pat_hprc_r2_v1.0.1_pt2.RepeatMasker.out"

output="upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/HG02027_pat_hprc_r2_v1.0.1.RepeatMasker.out"
cat $out1 > rm.tmp
head -n 3 rm.tmp > $output
sed '1,3d' $out1 $out2 >> $output
rm rm.tmp

## combine masked fastas
fa1="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt1/analysis/centromereAnnotation_outputs/4084a3cc-eec5-45ce-b48f-1b24e2118700/HG02027_pat_hprc_r2_v1.0.1_pt1.RepeatMasker.masked.fasta.gz"
fa2="/private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt2/analysis/centromereAnnotation_outputs/ea813b5a-7484-4405-a65d-81424326c81e/HG02027_pat_hprc_r2_v1.0.1_pt2.RepeatMasker.masked.fasta.gz"

output="upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/HG02027_pat_hprc_r2_v1.0.1.RepeatMasker.masked.fasta.gz"

zcat $fa1 $fa2 \
    | seqkit sort --natural-order --two-pass \
    | pigz > $output

## copy over archives (no need to combine)
cp \
    /private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt1/analysis/centromereAnnotation_outputs/81fc4a24-0e88-4b4d-b912-bdbf72babd02/HG02027_pat_hprc_r2_v1.0.1_pt1.formatted_repeat_masker.tar.gz \
    upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/
cp \
    /private/groups/hprc/qc/batch3/censat/manual/HG02027_hap1/HG02027_hap1_pt2/analysis/centromereAnnotation_outputs/1f7e96ce-8af8-4d0f-86f9-e4a62205ad55/HG02027_pat_hprc_r2_v1.0.1_pt2.formatted_repeat_masker.tar.gz \
    upload/HG02027/assemblies/freeze_2/annotation/repeat_masker/


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/qc/batch3/censat/s3_upload

cat <<EOF > censat_upload_linking_map.csv
column_name,destination
repeatMaskerTarGZ,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
rmOutFile,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
rmFinalMaskedFasta,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
rmRmskAlignBed,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
rmRmskBed,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
rmBed,upload/{sample_id}/assemblies/freeze_2/annotation/repeat_masker/
as_sf_bed,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
as_hor_bed,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
as_strand_bed,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
as_hor_sf_bed,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
centromeres,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
cenSatStrand,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
cenSatAnnotations,upload/{sample_id}/assemblies/freeze_2/annotation/censat/
EOF

awk -F',' 'NR==1 {print "sample_id,sample_hap," $3 "," substr($0, index($0, $4))} NR>1 {split($1, a, "_hap"); print a[1] "," $1 "," $3 "," substr($0, index($0, $4))}' \
    ../batch3_censat_outputs.csv \
    | grep -v "HG02027_hap1" \
    > batch3_censat_outputs_sample_oriented.csv


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch3_censat_outputs_sample_oriented.csv \
     --mapping_csv censat_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch3_censat_s3_upload.stderr

python3 ./generate_s3_paths.py \
    --csv_file batch3_censat_outputs_sample_oriented.csv \
    --mapping_csv censat_upload_linking_map.csv \
    --s3_base_path s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION


###############################################################################
##                                   DONE                                    ##
###############################################################################

mkdir -p /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/s3_upload
mkdir -p /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/manual/HG02027_hap1

cp manual/HG02027_hap1/batch3_censat_manual.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/manual/HG02027_hap1/

cp manual/HG02027_hap1/batch3_censat_manual_outputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/manual/HG02027_hap1/

## copy to github repo for notetaking
cp batch3_censat.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/

cp batch3_censat_outputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/     

cp batch3_censat_outputs_done.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/ 

cp s3_upload/batch3_censat_outputs_sample_oriented.csv\
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/s3_upload/

cp s3_upload/batch3_censat_outputs_sample_oriented_with_s3_paths.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/s3_upload/

cp -r \
     input_jsons/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch3/

## git add, commit, push

###############################################################################
##                                   DONE                                    ##
###############################################################################
