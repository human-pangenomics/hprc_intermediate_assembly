###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch4/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
     --field_mapping ../hprc_DeepPolisher_input_mapping.csv \
     --workflow_name hprc_DeepPolisher

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing

## clone repo

git clone https://github.com/human-pangenomics/hprc_intermediate_assembly.git

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## get wdl workflow from github
git clone https://github.com/miramastoras/hpp_production_workflows.git

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir batch4
cd batch4

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch4/* ./

mkdir hprc_DeepPolisher_submit_logs

## Launch batch 4

sbatch \
     launch_hprc_deepPolisher_batch4.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# update output file jsons
cd /private/groups/hprc/polishing/batch4

grep -v "sample_id" HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv | cut -f1 -d "," \
| while read line ; do sample_id=$line ; cp ${sample_id}/${sample_id}_hprc_DeepPolisher_outputs.json ${sample_id}/${sample_id}_hprc_DeepPolisher_outputs_updated.json; done

grep -v "sample_id" HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv | cut -f1 -d "," \
| while read line ; do sample_id=$line ; \
sed 's|,|\n|g' ${sample_id}/${sample_id}_hprc_DeepPolisher_outputs.json | \
cut -f 2 -d ":" | sed 's| ||g' | sed 's|}||g' | sed 's|"||g' | while read line ; do file=`basename $line`;\
newpath="/private/groups/hprc/polishing/batch4/${sample_id}/hprc_DeepPolisher_outputs/${file}" ; \
sed -i "s|${line}|${newpath}|g" ${sample_id}/${sample_id}_hprc_DeepPolisher_outputs_updated.json ;done; done

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch4

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
      --output_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.csv \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs_updated.json' \
      --submit_logs_directory hprc_DeepPolisher_submit_logs
