###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

# Remove top up data from data table

cd /Users/miramastoras/Desktop/Paten_lab/hprc_intermediate_assembly/polishing/batch5/hprc_DeepPolisher_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --field_mapping ../hprc_DeepPolisher_input_mapping.csv \
     --workflow_name hprc_DeepPolisher

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                             create launch polishing                      ##
###############################################################################

## on HPC...
cd /private/groups/hprc/polishing

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hprc_intermediate_assembly pull

## check that github repo is up to date
git -C /private/groups/hprc/polishing/hpp_production_workflows/ pull

mkdir -p batch5
cd batch5

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/polishing/hprc_intermediate_assembly/polishing/batch5/* ./

mkdir -p slurm_logs
export PYTHONPATH="/private/home/juklucas/miniconda3/envs/toil/bin/python"

# submit job
sbatch \
     --job-name=hprc-DeepPolisher-batch5 \
     --array=[1-24]%24 \
     --partition=high_priority \
     --cpus-per-task=32 \
     --mem=400gb \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --input_json_path '../hprc_DeepPolisher_input_jsons/${SAMPLE_ID}_hprc_DeepPolisher.json'

# resubmit samples which failed with no space error, using more CPUS to take over more of the node, and limiting my t
# tasks to 2 per node
sbatch \
     --job-name=hprc-DeepPolisher-batch5 \
     --array=[2,3,5,13,18,19,20,21,22]%9 \
     --partition=high_priority \
     --cpus-per-task=64 \
     --mem=400gb \
     --ntasks-per-node=2 \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --input_json_path '../hprc_DeepPolisher_input_jsons/${SAMPLE_ID}_hprc_DeepPolisher.json'

# resubmit samples which have no bam file, manually filter and polish the rest
sbatch \
     --job-name=hprc-DeepPolisher-batch5 \
     --array=[4,19,20,21,3]%9 \
     --partition=high_priority \
     --cpus-per-task=64 \
     --mem=400gb \
     --ntasks-per-node=2 \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_single_machine.sh \
     --wdl /private/groups/hprc/polishing/hpp_production_workflows/QC/wdl/workflows/hprc_DeepPolisher.wdl \
     --sample_csv HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --input_json_path '../hprc_DeepPolisher_input_jsons/${SAMPLE_ID}_hprc_DeepPolisher.json'

# as of 4/19/2024:
# samples failed, no bam file generated yet
# 4, 19, 20, 21, 3

# samples which have a bam from 4/5 run, need polisher filtering fixed manually
# 14, 15, 16, 13, 2, 18, 22, 5

# verify samples have bam files completed from April 5
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752 ;
    do ls -l ${sample}/analysis/hprc_DeepPolisher_outputs ; done

# apply GQ filters
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    # GQ 20 for 1bp insertions
    do bcftools view -Oz -i 'FORMAT/GQ>20 && (ILEN = 1)' \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ20_INS1.vcf.gz
    tabix -p vcf ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ20_INS1.vcf.gz
    # GQ 12 for 1bp del
    bcftools view -Oz -i 'FORMAT/GQ>12 && (ILEN = -1)' \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ12_DEL1.vcf.gz
    tabix -p vcf ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ12_DEL1.vcf.gz
    # GQ 5 for all other variants
    bcftools view -Oz -e 'FORMAT/GQ<=5 || (ILEN = 1) || (ILEN = -1)' \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ5.notINS1orDEL1.vcf.gz
    tabix -p vcf ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ5.notINS1orDEL1.vcf.gz
    # concat files
    bcftools concat -a -Oz \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ20_INS1.vcf.gz \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ12_DEL1.vcf.gz \
    ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.GQ5.notINS1orDEL1.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz
    tabix -p vcf ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz
    done

# check polisher numbers
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do echo $sample
    FILT=`zcat ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz | grep -v "^#" | wc -l`
    UNFILT=`zcat ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz | grep -v "^#" | wc -l`
    echo "filtered " $FILT
    echo "unfiltered " $UNFILT
    done

# rename unfiltered polished asm
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do mv ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap1.polished.fasta ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap1.polished.unfiltered.fasta
    mv ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap2.polished.fasta ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap2.polished.unfiltered.fasta
    done

# polish with filtered vcf
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do echo ${sample}
    bcftools consensus \
    -f /private/groups/hprc/assembly/batch4/${sample}/analysis/hic_hifiasm_assembly_cutadapt_multistep_outputs/${sample}.hap1.fa.gz \
    -H 2 ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap1.polished.fasta
    bcftools consensus \
    -f /private/groups/hprc/assembly/batch4/${sample}/analysis/hic_hifiasm_assembly_cutadapt_multistep_outputs/${sample}.hap2.fa.gz \
    -H 2 ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap2.polished.fasta
  done &> manual_polishing.log.txt

# rename hprc polisher vcf
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do mv ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.manual.hprc_filt.vcf.gz ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz
  done

# repolish 4/30/2024, realized I should have polished xygrouped.fa.gz instead
# polish with filtered vcf
for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do tabix -p vcf ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz
  done

for sample in HG02165 HG02965 NA18612 HG03209 NA18747 NA18522 HG00140 NA20752
    do echo ${sample}
    bcftools consensus \
    -f /private/groups/hprc/assembly/batch4/${sample}/analysis/hic_hifiasm_assembly_cutadapt_multistep_outputs/${sample}.hap1.xygrouped.fa.gz \
    -H 2 ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap1.polished.fasta
    bcftools consensus \
    -f /private/groups/hprc/assembly/batch4/${sample}/analysis/hic_hifiasm_assembly_cutadapt_multistep_outputs/${sample}.hap2.xygrouped.fa.gz \
    -H 2 ${sample}/analysis/hprc_DeepPolisher_outputs/polisher_output.vcf.gz \
    > ${sample}/analysis/hprc_DeepPolisher_outputs/${sample}_Hap2.polished.fasta
  done &> manual_polishing_redo.log.txt

###############################################################################
##                             write output files to csv                     ##
###############################################################################

cd /private/groups/hprc/polishing/batch5

## collect location of QC results
python3 /private/groups/hprc/polishing/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.polished.allDone.csv  \
      --json_location '{sample_id}_hprc_DeepPolisher_outputs.json'
