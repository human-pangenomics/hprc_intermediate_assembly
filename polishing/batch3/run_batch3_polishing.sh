###############################################################################
##                             remove topup from data table                  ##
###############################################################################

## on personal computer...
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3

# convert data table to tsv in excel
cp HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.tsv HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv
cut -f11 HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.tsv \
| sed 's/ //g' | sed 's/\"[][]//g' | sed 's/[][]\"//g' | sed 's/\,/\n/g' | \
while read line ; do
    if [[ "$line" =~ "TopUp" ]] ; then
        sed -i.bak "s|, ${line}||g" HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv
    fi
    if [[ "$line" =~ "Topoff" ]] ; then
        sed -i.bak "s|, ${line}||g" HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv
    fi
done

sed 's/\t/,/g' HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv > HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv

rm HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv.bak
rm HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.tsv
rm HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.tsv

###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch3/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv \
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

## Launch first 16 of batch 3 with new toil single machine method
#SBATCH --array=2-6,8-12,14-19%16
sbatch \
     launch_hprc_deepPolisher_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv

s
## Launch next 10 of batch 3 with new toil single machine method
#SBATCH --array=20-30%10
sbatch \
     launch_hprc_deepPolisher_batch3_next10.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv

# cancel and restart 15,16,19 because they were on phoenix 00 which has a problem
#SBATCH --array=15,16,19%3
sbatch \
     launch_hprc_deepPolisher_batch3_restart_15_16_19.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv

# launch final 10 minus the two that aren't done (39 and 37)
#SBATCH --array=31-36,38,40%8
sbatch \
     launch_hprc_deepPolisher_batch3.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv

###############################################################################
##                             write output files to csv                     ##
###############################################################################

# update output file jsons
cd /private/groups/hprc/polishing/batch3

grep -v "sample_id" HPRC_Intermediate_Assembly_s3Locs_Batch2.updated.noTopUp.csv | cut -f1 -d "," \
| while read line ; do sample_id=$line ; grep  \


# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch2

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp.updated.csv \
      --json_location '{sample_id}_hprc_polishing_QC_outputs.json' \
      --submit_logs_directory hprc_polishing_QC_submit_logs
