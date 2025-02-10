
cd /private/groups/hprc/qc/

mkdir -p chrom_assignment/batch1
cd chrom_assignment/batch1

###############################################################################
##                             Run chrom_assignment WDL                               ##
###############################################################################

wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.6.index.csv

cat << EOF > assign_chromosomes_input_mapping.csv
input,type,value
assign_chromosomes.assembly_name,scalar,\$input.assembly_name
assign_chromosomes.input_asm,scalar,\$input.assembly
assign_chromosomes.chrom_assignment_ignore_bed,scalar,/private/groups/hprc/ref_files/chm13/chm13_ignore_rDNA_PARs.bed
assign_chromosomes.ref_asm,scalar,/private/groups/hprc/ref_files/chm13/chm13v2.0.fa.gz
EOF


awk -F',' 'BEGIN {OFS=","} NR==1 {$1="sample_name"; print "sample_id",$0; next} {print $1"_hap"$2,$0}' \
    assemblies_pre_release_v0.6.index.csv \
    > batch1_assign_chromosomes.csv

mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch1_assign_chromosomes.csv \
     --field_mapping ../assign_chromosomes_input_mapping.csv  \
     --workflow_name assign_chromosomes

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=assign_chromosomes \
     --array=[1-466]%100 \
     --cpus-per-task=10 \
     --threads-per-core=2 \
     --mem=32gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/annotation/wdl/tasks/assign_chromosomes.wdl \
     --sample_csv batch1_assign_chromosomes.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_assign_chromosomes.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_assign_chromosomes.csv \
    --output_data_table batch1_assign_chromosomes_outputs.csv  \
    --json_location '{sample_id}_assign_chromosomes_outputs.json'


##############################################################################
#                          Upload To HPRC Bucket                            ##
##############################################################################

mkdir s3_upload
cd s3_upload

## then fix column in Excel
awk -F',' 'BEGIN {OFS=","} NR==1 {$2="sample_hap_id"; print; next} {split($1, a, "_"); $1=a[1]; print}' \
    ../batch1_assign_chromosomes_outputs.csv \
    | head -n -4 \
    > batch1_assign_chromosomes_outputs_sample_oriented.csv

cat <<EOF > assign_chrom_upload_linking_map.csv
column_name,destination
t2t_chrom_tsv,upload/{sample_id}/assemblies/freeze_2/annotation/chrom_assignment/
chrom_alias_txt,upload/{sample_id}/assemblies/freeze_2/annotation/chrom_assignment/
gaps_bed,upload/{sample_id}/assemblies/freeze_2/annotation/chrom_assignment/
telo_bed,upload/{sample_id}/assemblies/freeze_2/annotation/chrom_assignment/
mashmap_paf,upload/{sample_id}/assemblies/freeze_2/annotation/chrom_assignment/mashmap/asm_to_chm13v2/
EOF

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch1_assign_chromosomes_outputs_sample_oriented.csv \
     --mapping_csv assign_chrom_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch1_chrom_assignment_s3_upload.stderr


###############################################################################
##                          Update GitHub Repo.                              ##
###############################################################################

cd /private/groups/hprc/qc/chrom_assignment/batch1

## copy to github repo for notetaking
cp batch1_assign_chromosomes.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chrom_assignment/batch1/

cp batch1_assign_chromosomes_outputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chrom_assignment/batch1/  
    
cp -r \
     input_jsons/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chrom_assignment/batch1/

## git add, commit, push

###############################################################################
##                                   DONE                                    ##
###############################################################################
