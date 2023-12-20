
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch1/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira.csv \
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
git -C /private/groups/hprc/hprc_intermediate_assembly pull

## get wdl workflow from github
git clone https://github.com/miramastoras/hpp_production_workflows.git

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

# manually add in polishing docker v0.0.8_12122023 until its publicly released
vim /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl

mkdir batch1
cd batch1

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch1/* ./

mkdir hprc_DeepPolisher_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_deepPolisher_batch1_array.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira.csv
