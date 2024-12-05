
cd /private/groups/hprc/qc/

mkdir -p batch1/censat
cd batch1/censat

###############################################################################
##                             Run Censat WDL                                ##
###############################################################################

wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.2.index.csv


cat<<EOF>rewrite_input.py
#!/usr/bin/env python3
import csv
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

with open(input_file, 'r', encoding='utf-8-sig') as infile, open(output_file, 'w', newline='', encoding='utf-8') as outfile:
    reader = csv.DictReader(infile)
    writer = csv.writer(outfile)
    
    # Write header
    writer.writerow(['sample_id', 'asm'])
    
    for row in reader:
        sample_id = row['sample_id']
        hap1_fa_gz = row['hap1_fa_gz']
        hap2_fa_gz = row['hap2_fa_gz']
        
        # Write hap1 row
        writer.writerow([f"{sample_id}_hap1", hap1_fa_gz])
        
        # Write hap2 row
        writer.writerow([f"{sample_id}_hap2", hap2_fa_gz])

print(f"Processed data written to {output_file}")
EOF

python3 rewrite_input.py \
    assemblies_pre_release_v0.2.index.csv \
    batch1_censat.csv

cat <<EOF > censat_input_mapping.csv 
input,type,value
centromereAnnotation.fasta,scalar,\$input.asm
centromereAnnotation.rDNAhmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/rDNA1.0.hmm
centromereAnnotation.AS_hmm_profile,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-HORs-hmmer3.4-071024.hmm
centromereAnnotation.AS_hmm_profile_SF,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/AS-SFs-hmmer3.0.290621.hmm
centromereAnnotation.additionalRMModels,scalar,/private/home/juklucas/github/alphaAnnotation/utilities/xy_apes_y_human_newmodels.embl
EOF


## check that github repo is up to date
git -C /private/home/juklucas/github/alphaAnnotation pull

## check which commit we are on:
git -C /private/home/juklucas/github/alphaAnnotation log -1
# commit 174671ca55e4c21abf0867e56cf93fda41a8d2e8 (HEAD -> main, origin/main, origin/HEAD)

mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../batch1_censat.csv \
     --field_mapping ../censat_input_mapping.csv \
     --workflow_name censat

cd ..

mkdir -p slurm_logs

sbatch \
     --job-name=censat \
     --array=[1-200]%40 \
     --cpus-per-task=64 \
     --mem=400gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch1_censat.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'

## had some failures coming from how repeat masker was handling many files (from 
## having many contigs). So I will aggregate the results I have and then restart...

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_censat.csv \
    --output_data_table batch1_censat_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'

## nothing is sacred
head -n1 batch1_censat_outputs.csv > batch1_censat_unfinished.csv
grep ',,,,' batch1_censat_outputs.csv >> batch1_censat_unfinished.csv

sbatch \
     --job-name=censat \
     --array=[1-173%50 \
     --cpus-per-task=64 \
     --threads-per-core=2 \
     --mem=300gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch1_censat_unfinished.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_censat.csv \
    --output_data_table batch1_censat_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'
    

## Had a few random failures...    
# HG02027_hap1 43
# HG01786_hap2 274
# HG03139_hap1 319
# HG03139_hap2 320

sbatch \
     --job-name=censat \
     --array=[43,274,319,320]%4 \
     --cpus-per-task=192 \
     --threads-per-core=2 \
     --mem=900gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch1_censat.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'

sbatch \
     --job-name=censat \
     --array=[43,274]%2 \
     --cpus-per-task=192 \
     --threads-per-core=2 \
     --mem=900gb \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/home/juklucas/github/alphaAnnotation/cenSatAnnotation/centromereAnnotation.wdl \
     --sample_csv batch1_censat.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_censat.json'

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table batch1_censat.csv \
    --output_data_table batch1_censat_outputs.csv  \
    --json_location '{sample_id}_centromereAnnotation_outputs.json'

grep -v -E "^HG02027|^HG01786" batch1_censat_outputs.csv > batch1_censat_outputs_done.csv


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

mkdir s3_upload
cd s3_upload

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

awk -F',' 'NR==1 {print $1",sample_hap,"substr($0, index($0,$2))} NR>1 {split($1, a, "_hap"); print a[1]","$1","substr($0, index($0,$2))}' \
    ../batch1_censat_outputs_done.csv \
    > batch1_censat_outputs_sample_oriented.csv


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file batch1_censat_outputs_sample_oriented.csv \
     --mapping_csv censat_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch1_censat_s3_upload.stderr

###############################################################################
##                                   DONE                                    ##
###############################################################################

mkdir -p /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch1/

## copy to github repo for notetaking
cp batch1_censat.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch1/

cp batch1_censat_outputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch1/     

cp batch1_censat_outputs_done.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch1/
    
cp -r \
     input_jsons/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/batch1/

## git add, commit, push

###############################################################################
##                                   DONE                                    ##
###############################################################################
