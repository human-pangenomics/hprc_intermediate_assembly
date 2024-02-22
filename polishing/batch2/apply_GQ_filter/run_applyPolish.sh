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



###############################################################################
##                             create input jsons                            ##
###############################################################################

## back on personal computer...
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/

# add column for filtered vcf in csv table
HEAD=`head -n 1 intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.csv`
echo "filteredDeepPolisherVcf",${HEAD} >


# Generate apply polish toil json files from csv sample table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/applyPolish_input_jsons
python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.csv \
     --field_mapping ../applyPolish.input.mapping.mat.csv \
     --workflow_name applyPolish.mat

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.csv \
     --field_mapping ../applyPolish.input.mapping.pat.csv \
     --workflow_name applyPolish.pat





###############################################################################
##                             create launch apply polish                    ##
###############################################################################

## on HPC...
cd /private/groups/patenlab/mira

## clone repo
git clone https://github.com/miramastoras/phoenix_batch_submissions.git

## check that github repo is up to date
git -C /private/groups/patenlab/mira/phoenix_batch_submissions pull

## check that hpp production wdls github repo is up to date
git -C /private/home/mmastora/progs/hpp_production_workflows pull

# move to work dir
cd /private/groups/patenlab/mira/hprc_polishing/qv_problems/HPRC_intermediate_asm/GQ_filters/applyPolish

## get files to run in polishing folder ...
cp -r /private/groups/patenlab/mira/phoenix_batch_submissions/polishing/applyPolish/HPRC_int_asm_GQ_filters/* ./

mkdir applyPolish_submit_logs

## launch with slurm array

sbatch \
     launch_applyPolish.sh \
     HPRC_int_asm_GQfilters.samples.csv
#
###############################################################################
##                             write output files to csv                     ##
###############################################################################


# on hprc after entire batch has finished
cd /private/groups/patenlab/mira/hprc_polishing/qv_problems/HPRC_intermediate_asm/GQ_filters/applyPolish

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_int_asm_GQfilters.samples.csv \
      --output_data_table ./HPRC_int_asm_GQfilters.samples.mat.csv \
      --json_location '{sample_id}_applyPolish_mat_outputs.json'

sed -i "s|asmPolished|polishedAsmHap2|g" ./HPRC_int_asm_GQfilters.samples.mat.csv

python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table ./HPRC_int_asm_GQfilters.samples.mat.csv \
      --output_data_table ./HPRC_int_asm_GQfilters.samples.updated.csv \
      --json_location '{sample_id}_applyPolish_pat_outputs.json'

sed -i "s|asmPolished|polishedAsmHap1|g" ./HPRC_int_asm_GQfilters.samples.updated.csv
