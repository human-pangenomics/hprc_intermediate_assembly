###############################################################################
##                             apply custom GQ filter                      ##
###############################################################################
## on HPC...

cd /private/groups/hprc/polishing/batch2

mkdir -p apply_GQ_filter

ls | grep ^HG | while read line ; do
mkdir -p apply_GQ_filter/${line}/filtered_vcf/
bcftools view -Oz -i 'FORMAT/GQ>20 && (ILEN = 1)' ${line}/hprc_DeepPolisher_outputs/polisher_output.vcf.gz > ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ20_INS1.vcf.gz
tabix -p vcf ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ20_INS1.vcf.gz
bcftools view -Oz -i 'FORMAT/GQ>12 && (ILEN = -1)' ${line}/hprc_DeepPolisher_outputs/polisher_output.vcf.gz > ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ12_DEL1.vcf.gz
tabix -p vcf ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ12_DEL1.vcf.gz
bcftools view -Oz -e 'FORMAT/GQ<=5 || (ILEN = 1) || (ILEN = -1)' ${line}/hprc_DeepPolisher_outputs/polisher_output.vcf.gz > ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ5.notINS1orDEL1.vcf.gz
tabix -p vcf ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ5.notINS1orDEL1.vcf.gz
bcftools concat -a -Oz ./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ20_INS1.vcf.gz \
./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ12_DEL1.vcf.gz \
./apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ5.notINS1orDEL1.vcf.gz \
> apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ_filtered.vcf.gz
done

# check merge worked
cd apply_GQ_filter/HG00408/filtered_vcf
ls *.vcf.gz | while read line ; do echo $line ; zcat $line | grep -v "^#" | wc -l ; done

# check filters worked
bcftools view -i 'FORMAT/GQ<20 && (ILEN = 1)' HG00408.polisher_output.GQ_filtered.vcf.gz
bcftools view -i 'FORMAT/GQ<12 && (ILEN = -1)' HG00408.polisher_output.GQ_filtered.vcf.gz
bcftools view -i 'FORMAT/GQ<=5' HG00408.polisher_output.GQ_filtered.vcf.gz


ls | grep ^HG | while read line ; do
echo /private/groups/hprc/polishing/batch2/apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ_filtered.vcf.gz
done


###############################################################################
##                             update sample table with filtered vcf         ##
###############################################################################
## back on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/


# create copy of csv with new column for filtered vcf, with NA in each row

head -n 1 intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv > tmp.csv
grep -v "sample_id"  intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv \
| cut -f1 -d"," | while read line ; do grep $line intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv \
| sed "s|NA|/private/groups/hprc/polishing/batch2/apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ_filtered.vcf.gz|g" >> tmp.csv; done

mv tmp.csv intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv
###############################################################################
##                             create input jsons                            ##
###############################################################################

## back on personal computer...
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/

# Generate apply polish toil json files from csv sample table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/applyPolish_input_jsons
python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv \
     --field_mapping ../applyPolish.input.mapping.mat.csv \
     --workflow_name applyPolish.mat

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv \
     --field_mapping ../applyPolish.input.mapping.pat.csv \
     --workflow_name applyPolish.pat

###############################################################################
##                             create launch apply polish                    ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

# move to work dir
cd /private/groups/hprc/polishing/batch2/apply_GQ_filter

## get files to run in polishing folder ...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/* ./

mkdir applyPolish_submit_logs

## launch with slurm array

sbatch \
     launch_applyPolish.sh \
     intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv
#
###############################################################################
##                             write output files to csv                     ##
###############################################################################

# on hprc after entire batch has finished
cd /private/groups/hprc/polishing/batch2/apply_GQ_filter

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.csv \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.mat.csv \
      --json_location '{sample_id}_applyPolish_mat_outputs.json'

sed -i "s|asmPolished|polishedGQFilterAsmHap2|g" ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.mat.csv

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.mat.csv  \
      --output_data_table ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv  \
      --json_location '{sample_id}_applyPolish_pat_outputs.json'

sed -i "s|asmPolished|polishedGQFilterAsmHap1|g" ./intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv

rm intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.mat.csv
