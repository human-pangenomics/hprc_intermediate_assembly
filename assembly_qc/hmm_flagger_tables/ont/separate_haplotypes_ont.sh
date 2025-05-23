#!/bin/bash
#SBATCH --job-name=separate_haps_ont_masri
#SBATCH --partition=long
#SBATCH --mail-user=masri@ucsc.edu
#SBATCH --nodes=1
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=2gb
#SBATCH --cpus-per-task=2
#SBATCH --output=%x.%j.log
#SBATCH --time=100:00:00

cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hmm_flagger_tables/ont

touch csv2tab && chmod u+x csv2tab

#Add to it
cat <<EOF > csv2tab
#!/usr/bin/env python
import csv, sys
csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))
EOF

BASE="https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC"

WORKING_DIR="$PWD"

####################
# batch1_jan_12_2025
####################

echo "Downloading and separating ONT-based HMM-Flagger bed files for batch1_jan_12_2025 ... "

# download BED files, separate them by haplotypes, upload them to the related s3 bucket
while read line; do
	# here I grep ".cov.gz" to make sure the pipeline was run successfully for this sample
        SAMPLE=$(echo $line | grep ".cov.gz" | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $1}')
        if [[ ${SAMPLE} == "" ]];then
                continue
        fi
	# echo sample to create a list of samples whose bed files could be separated by haplotype
	echo ${SAMPLE}

	# get link
        BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed

	# make a directory to download bed file and create haplotype-specific bed files
	mkdir -p ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
	cd ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
	wget ${BED_NOHAP_v1dot1}
        cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#2#" > ${SAMPLE}.hap2.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#1#" > ${SAMPLE}.hap1.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	cd ${WORKING_DIR}
done < ${WORKING_DIR}/../../batch1_jan_12_2025/hmm_flagger/ont/hmm_flagger_ont_data_table.output.csv > ${WORKING_DIR}/samples_list_batch1_jan_12_2025.txt

#########
# batch1
#########

echo "Downloading and separating ONT-based HMM-Flagger bed files for batch1 (after excluding batch1_jan_12_2025) ... "

# download BED files, separate them by haplotypes, upload them to the related s3 bucket
while read line; do
        # here I grep ".cov.gz" to make sure the pipeline was run successfully for this sample
	# exclude the samples that were among batch1_jan_12_2025
        SAMPLE=$(echo $line | grep -v -F -f ${WORKING_DIR}/samples_list_batch1_jan_12_2025.txt | grep ".cov.gz" | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $1}')
        if [[ ${SAMPLE} == "" ]];then
                continue
        fi
	# echo sample to create a list of samples whose bed files could be separated by haplotype
        echo ${SAMPLE}

	# get link
        BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed

	# make a directory to download bed file and create haplotype-specific bed files
        mkdir -p ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
        cd ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
        wget ${BED_NOHAP_v1dot1}
        cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#2#" > ${SAMPLE}.hap2.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
        cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#1#" > ${SAMPLE}.hap1.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	cd ${WORKING_DIR}
done < ${WORKING_DIR}/../../batch1/hmm_flagger/ont/hmm_flagger_ont_data_table.output.csv > ${WORKING_DIR}/samples_list_only_batch1.txt



#########
# batch2
#########

echo "Downloading and separating ONT-based HMM-Flagger bed files for batch2 ... "

# download BED files, separate them by haplotypes, upload them to the related s3 bucket
while read line; do
	# here I grep ".cov.gz" to make sure the pipeline was run successfully for this sample
        SAMPLE=$(echo $line | grep ".cov.gz" | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $1}')
        if [[ ${SAMPLE} == "" ]];then
                continue
        fi
	# echo sample to create a list of samples whose bed files could be separated by haplotype
	echo ${SAMPLE}

	# get link
        BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed

	# make a directory to download bed file and create haplotype-specific bed files
	mkdir -p ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
	cd ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont
	wget ${BED_NOHAP_v1dot1}
        cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#2#" > ${SAMPLE}.hap2.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	cat ${WORKING_DIR}/s3_upload_hap_separated/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed | \
		grep "#1#" > ${SAMPLE}.hap1.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	cd ${WORKING_DIR}
done < ${WORKING_DIR}/../../batch2/hmm_flagger/ont/hmm_flagger_ont_data_table.output.csv > ${WORKING_DIR}/samples_list_batch2.txt


echo "Uploading ONT-based bed files separated by haplotype ..."

cd ${WORKING_DIR}

ssds staging upload \
    --submission-id ca366a13-5bad-487b-8a57-97344e9aa0e4 \
    s3_upload_hap_separated \
    &>>separate_haplotypes_ont_s3_upload.stderr


