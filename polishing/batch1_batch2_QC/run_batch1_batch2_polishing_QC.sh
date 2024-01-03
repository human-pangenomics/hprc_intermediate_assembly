###############################################################################
##                             create sample table                           ##
###############################################################################

## on personal computer, manually add sample yak column from
# intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch1_2_yak_count.updated.csv
# to intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2.updated.csv
# and add HG01975 from batch 1

###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch1/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../intAsm_batch1_batch2_polishingQC_sample_table.csv \
     --field_mapping ../hprc_polishing_QC_input_mapping.csv \
     --workflow_name hprc_polishing_QC

## add/commit/push to github (hprc_intermediate_assembly)
