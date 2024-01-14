
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.polishing_batch3.csv \
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

mkdir batch3
cd batch3

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch3/* ./

mkdir hprc_DeepPolisher_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_deepPolisher_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.polishing_batch3.csv

## relaunch only 4 because ran out of space in hprc folder 
sbatch \
     launch_hprc_deepPolisher_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.polishing_batch3.csv
###############################################################################
##                             write output files to csv                     ##
###############################################################################
