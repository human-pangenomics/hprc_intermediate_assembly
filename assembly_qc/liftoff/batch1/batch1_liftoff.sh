
cd /private/groups/hprc/qc/

mkdir -p liftoff/batch1
cd liftoff/batch1

###############################################################################
##                             Run Liftoff WDL                               ##
###############################################################################

wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.3.index.csv


## then fix header by hand
awk -F',' 'BEGIN {OFS=","} NR==1 {print "sample_id," $0; next} {print $1 "_hap" $2, $0}' \
    assemblies_pre_release_v0.3.index.csv \
    > batch1_liftoff.csv

cat <<EOF > liftoff_input_mapping.csv 
input,type,value
runLiftoff.liftoff.sample,scalar,\$input.sample_id
runLiftoff.liftoff.suffix,scalar,hprc_r2_v1_liftoff
runLiftoff.liftoff.referenceFastaGz,scalar,/private/groups/hprc/ref_files/chm13/chm13v2.0.fa.gz
runLiftoff.liftoff.geneGff3,scalar,/private/groups/hprc/ref_files/liftoff/chm13v2.0_RefSeq_Liftoff_v5.1.gff3
runLiftoff.liftoff.assemblyFastaGz,scalar,\$input.assembly
EOF


mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch1_liftoff.csv \
     --field_mapping ../liftoff_input_mapping.csv  \
     --workflow_name liftoff

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=liftoff \
     --array=[1-432]%40 \
     --cpus-per-task=10 \
     --threads-per-core=2 \
     --mem=40gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/annotation/wdl/tasks/liftoff.wdl \
     --sample_csv batch1_liftoff.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_liftoff.json'


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_liftoff.csv \
    --output_data_table batch1_liftoff_outputs.csv  \
    --json_location '{sample_id}_liftoff_outputs.json'



## many failed, it seems they were memory killed. Not sure if that was from
## using too much memory or other jobs used too much memory on the same machines
## looking at the logs, nothing seems to use too much memory, but it could be
## that there are multiple jobs running at once (multiple minimap2 commands)
## and they add up to more than the amount of memory I provided?

## also, some of the samples had the input gff3 as input, so I updated the WDL
## to correctly pull only the sample's annotation!

## rerun with more memory and the updated output declaration.


###############################################################################
##                             Run Liftoff WDL                               ##
###############################################################################

## pull samples that failed:
grep -v "liftoff" batch1_liftoff_outputs.csv > batch1_liftoff_incomplete.csv

## pull samples with the input listed as the output (which need to be rerun)
grep "chm13v2.0_RefSeq_Liftoff_v5.1.gff3" batch1_liftoff_outputs.csv > batch1_rerun.csv

## combine...
cat batch1_liftoff_incomplete.csv batch1_rerun.csv > batch1_liftoff_2.csv

## up the memory to 150GB just to be sure it will work
cat <<EOF > liftoff_input_mapping_2.csv 
input,type,value
runLiftoff.liftoff.sample,scalar,\$input.sample_id
runLiftoff.liftoff.suffix,scalar,hprc_r2_v1_liftoff
runLiftoff.liftoff.referenceFastaGz,scalar,/private/groups/hprc/ref_files/chm13/chm13v2.0.fa.gz
runLiftoff.liftoff.geneGff3,scalar,/private/groups/hprc/ref_files/liftoff/chm13v2.0_RefSeq_Liftoff_v5.1.gff3
runLiftoff.liftoff.assemblyFastaGz,scalar,\$input.assembly
runLiftoff.liftoff.memSizeGB,scalar,150
EOF

cd input_jsons

## create input jsons
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch1_liftoff_2.csv \
     --field_mapping ../liftoff_input_mapping_2.csv  \
     --workflow_name liftoff

cd ..

## get updated WDL
git -C /private/home/juklucas/github/hpp_production_workflows/ pull

sbatch \
     --job-name=liftoff \
     --array=[1-258]%50 \
     --cpus-per-task=10 \
     --threads-per-core=2 \
     --mem=150gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/annotation/wdl/tasks/liftoff.wdl \
     --sample_csv batch1_liftoff_2.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_liftoff.json'

## collect all results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_liftoff.csv \
    --output_data_table batch1_liftoff_outputs_check.csv  \
    --json_location '{sample_id}_liftoff_outputs.json'    


## one sample still failed... 
## Update input json by hand to increase memory
## nano input_jsons/NA19391_hap2_liftoff.json

## then run again (allocating more memory as neccesary)
sbatch \
     --job-name=liftoff \
     --array=[57] \
     --cpus-per-task=10 \
     --threads-per-core=2 \
     --mem=500gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/annotation/wdl/tasks/liftoff.wdl \
     --sample_csv batch1_liftoff_2.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_liftoff.json'

## collect one last time...
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_liftoff.csv \
    --output_data_table batch1_liftoff_outputs_final.csv  \
    --json_location '{sample_id}_liftoff_outputs.json'    

mv batch1_liftoff_outputs_final.csv batch1_liftoff_outputs.csv


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

mkdir s3_upload
cd s3_upload

## then fix column in Excel
awk -F',' 'NR==1 {print $1",sample_hap,"substr($0, index($0,$2))} NR>1 {split($1, a, "_hap"); print a[1]","$1","substr($0, index($0,$2))}' \
    ../batch1_liftoff_outputs.csv \
    > batch1_liftoff_outputs_sample_oriented.csv

cat <<EOF > censat_upload_linking_map.csv
column_name,destination
outputGff3,upload/{sample_id}/assemblies/freeze_2/annotation/liftoff/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch1_liftoff_outputs_sample_oriented.csv \
     --mapping_csv censat_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch1_liftoff_s3_upload.stderr

###############################################################################
##                                   DONE                                    ##
###############################################################################
