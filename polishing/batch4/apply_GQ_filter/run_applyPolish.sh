###############################################################################
##                             apply custom GQ filter                      ##
###############################################################################
## on HPC...

cd /private/groups/hprc/polishing/batch4

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

# check merge worked - variant counts add up
cd apply_GQ_filter/HG02559/filtered_vcf
ls *.vcf.gz | while read line ; do echo $line ; zcat $line | grep -v "^#" | wc -l ; done

# check filters worked - empty vcf produced
bcftools view -i 'FORMAT/GQ<20 && (ILEN = 1)' HG02559.polisher_output.GQ_filtered.vcf.gz
bcftools view -i 'FORMAT/GQ<12 && (ILEN = -1)' HG02559.polisher_output.GQ_filtered.vcf.gz
bcftools view -i 'FORMAT/GQ<=5' HG02559.polisher_output.GQ_filtered.vcf.gz

###############################################################################
##                             update sample table with filtered vcf         ##
###############################################################################
## back on personal computer...

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch4/apply_GQ_filter/

# create copy of csv
cp HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.csv HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv
# open in excel and ad new column of NAs, DeepPolisherFilteredVcf
head -n 1 HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv > tmp.csv
grep -v "sample_id" HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv \
| cut -f1 -d"," | while read line ; do grep $line HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv \
| sed "s|NA|/private/groups/hprc/polishing/batch4/apply_GQ_filter/${line}/filtered_vcf/${line}.polisher_output.GQ_filtered.vcf.gz|g" >> tmp.csv; done

mv tmp.csv HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv
###############################################################################
##                             create input jsons                            ##
###############################################################################

## back on personal computer...

# Generate apply polish toil json files from csv sample table
mkdir -p  /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch4/apply_GQ_filter/applyPolish_input_jsons
cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch4/apply_GQ_filter/applyPolish_input_jsons

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv \
     --field_mapping ../applyPolish.input.mapping.mat.csv \
     --workflow_name applyPolish.mat

python3 /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv \
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
cd /private/groups/hprc/polishing/batch4/apply_GQ_filter

## get files to run in polishing folder ...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch4/apply_GQ_filter/* ./

mkdir applyPolish_submit_logs

## launch with slurm array

sbatch \
     launch_applyPolish.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.polished.filterVcf.csv
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
