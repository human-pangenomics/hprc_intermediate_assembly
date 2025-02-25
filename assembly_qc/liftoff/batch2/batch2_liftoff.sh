
cd /private/groups/hprc/qc/

mkdir -p liftoff/batch2
cd liftoff/batch2

###############################################################################
##                             Run Liftoff WDL                               ##
###############################################################################

## get assembly table and create haplotype-specific sample_ids
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.6.1.index.csv

awk -F',' 'BEGIN {OFS=","} NR==1 {$1="sample_name"; print "sample_id",$0; next} {print $1"_hap"$2,$0}' \
    assemblies_pre_release_v0.6.1.index.csv \
    > assemblies_pre_release_v0.6.1_hap_formatted.index.csv

## get samples that have been run through censat
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/annotation/liftoff/liftoff_pre_release_v0.2.index.csv

## and remove them to create index file
awk -F',' 'NR==FNR {samples[$1]; next} !($2 in samples)' \
    liftoff_pre_release_v0.2.index.csv \
    assemblies_pre_release_v0.6.1_hap_formatted.index.csv \
    | grep -vE "HG002|CHM13|GRCh38" \
    > batch2_liftoff.csv


## set mem to 150GB just to be sure it will work
cat <<EOF > liftoff_input_mapping.csv 
input,type,value
runLiftoff.liftoff.sample,scalar,\$input.sample_id
runLiftoff.liftoff.suffix,scalar,hprc_r2_v1_liftoff
runLiftoff.liftoff.referenceFastaGz,scalar,/private/groups/hprc/ref_files/chm13/chm13v2.0.fa.gz
runLiftoff.liftoff.geneGff3,scalar,/private/groups/hprc/ref_files/liftoff/chm13v2.0_RefSeq_Liftoff_v5.1.gff3
runLiftoff.liftoff.assemblyFastaGz,scalar,\$input.assembly
runLiftoff.liftoff.memSizeGB,scalar,150
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch2_liftoff.csv \
     --field_mapping ../liftoff_input_mapping.csv  \
     --workflow_name liftoff

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=liftoff \
     --array=[1-37]%10 \
     --cpus-per-task=10 \
     --threads-per-core=2 \
     --mem=150gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/annotation/wdl/tasks/liftoff.wdl \
     --sample_csv batch2_liftoff.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_liftoff.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch2_liftoff.csv \
    --output_data_table batch2_liftoff_outputs.csv  \
    --json_location '{sample_id}_liftoff_outputs.json'


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/qc/liftoff/batch2

mkdir -p s3_upload
cd s3_upload

## then fix column in Excel
awk -F',' 'NR==1 {print $1",sample_hap,"substr($0, index($0,$2))} NR>1 {split($1, a, "_hap"); print a[1]","$1","substr($0, index($0,$2))}' \
    ../batch2_liftoff_outputs.csv \
    > batch2_liftoff_outputs_sample_oriented.csv

## then fix column in Excel
awk -F',' 'BEGIN {OFS=","} NR==1 {$2="sample_hap_id"; print; next} {split($1, a, "_"); $1=a[1]; print}' \
    ../batch2_liftoff_outputs.csv \
    > batch2_liftoff_outputs_sample_oriented.csv

cat <<EOF > liftoff_upload_linking_map.csv
column_name,destination
outputGff3,upload/{sample_id}/assemblies/freeze_2/annotation/liftoff/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch2_liftoff_outputs_sample_oriented.csv \
     --mapping_csv liftoff_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch2_liftoff_s3_upload.stderr

python3 ../../../chrom_assignment/batch1/generate_s3_path.py \
    --csv_file batch2_liftoff_outputs_sample_oriented.csv \
    --mapping_csv liftoff_upload_linking_map.csv \
    --s3_base_path s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION


###############################################################################
##                          Update GitHub Repo.                              ##
###############################################################################

cd /private/groups/hprc/qc/liftoff/batch2

## copy to github repo for notetaking
cp batch2_liftoff.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/liftoff/batch2/

cp batch2_liftoff_outputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/liftoff/batch2/  

cp s3_upload/batch2_liftoff_outputs_sample_oriented_with_s3_paths.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/liftoff/batch2/ 
     
cp -r \
     input_jsons/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/liftoff/batch2/

## git add, commit, push

###############################################################################
##                                   DONE                                    ##
###############################################################################
