###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3/hprc_polishing_QC/hprc_polishing_QC_input_jsons

python3 ../../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

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

mkdir -p batch3/hprc_polishing_QC
cd batch3/hprc_polishing_QC

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch3/hprc_polishing_QC/* ./

mkdir hprc_polishing_QC_submit_logs

## launch with slurm array job
sbatch \
     launch_hprc_polishing_QC_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.csv

# relaunch 14 from batch 3 QC which failed with stale file handle error
#SBATCH --array=14%1
sbatch \
     launch_hprc_polishing_QC_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.csv

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# concatenate output csv files
grep -v "sample_id" HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.csv | cut -f1 -d "," \
| while read line ; do sample_id=$line ; \
tail -n2 ${sample_id}/hprc_polishing_QC_outputs/${sample_id}.polishing.QC.csv >> batch3.polishing.QC.csv ; done



# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch3

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.csv \
      --output_data_table ./HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.updated.postQC.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json' \
      --submit_logs_directory hprc_polishing_QC_submit_logs
