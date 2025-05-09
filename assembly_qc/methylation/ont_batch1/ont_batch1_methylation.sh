
cd /private/groups/hprc/methylation/ont_modkit


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

mkdir s3_upload
cd s3_upload


cat <<EOF > modkit_upload_linking_map.csv
column_name,destination
hap1_pileup_bed,upload/{sample_id}/assemblies/freeze_2/annotation/methylation/ont/
hap1_pileup_bigwig,upload/{sample_id}/assemblies/freeze_2/annotation/methylation/ont/
hap2_pileup_bigwig,upload/{sample_id}/assemblies/freeze_2/annotation/methylation/ont/
hap2_pileup_bed,upload/{sample_id}/assemblies/freeze_2/annotation/methylation/ont/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file ../hprc_ont_modkit_outputs.csv \
     --mapping_csv modkit_upload_linking_map.csv

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>batch1_ont_meth_s3_upload.stderr

cd ..

python3 /private/groups/hprc/qc/chrom_assignment//batch1/generate_s3_path.py \
    --csv_file hprc_ont_modkit_outputs.csv \
    --mapping_csv s3_upload/modkit_upload_linking_map.csv \
    --s3_base_path s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION


###############################################################################
##                          Update GitHub Repo.                              ##
###############################################################################

cd /private/groups/hprc/methylation/ont_modkit

## copy to github repo for notetaking
cp hprc_ont_modkit_outputs.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/methylation/ont_batch1/

cp hprc_ont_modkit_outputs_with_s3_paths.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/methylation/ont_batch1/
    
cp hprc_ont_modkit_inputs.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/methylation/ont_batch1/
    
cp launch_hprc_ont_modkit.ipynb \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/methylation/ont_batch1/
    
cp -r \
     input_jsons/ \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/methylation/ont_batch1/

## git add, commit, push

###############################################################################
##                                   DONE                                    ##
###############################################################################
