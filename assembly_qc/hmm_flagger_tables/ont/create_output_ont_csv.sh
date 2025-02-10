cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hmm_flagger_tables/ont

touch csv2tab && chmod u+x csv2tab

#Add to it
cat <<EOF > csv2tab
#!/usr/bin/env python
import csv, sys
csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))
EOF

OUTPUT_TSV="hmm_flagger_ont_data_table.output_s3.csv"
BASE="https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC"
BASE_DIR="/private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc"

printf "sample_id,mapping_info,bam_link,bai_link,cov_gz_link,hmm_flagger_v1.1_stats_tsv_link,hmm_flagger_v1.1_nohap_bed_link,hmm_flagger_v1.1_nohap_bed_hap1_link,hmm_flagger_v1.1_nohap_bed_hap2_link,hmm_flagger_v1.1_prediction_bed_link\n" > ${OUTPUT_TSV}

# download BED files, separate them by haplotypes, upload them to the related s3 bucket
while read SAMPLE; do
	MAPPING_SUFFIX=$(cat ${BASE_DIR}/batch1_jan_12_2025/hmm_flagger/ont/hmm_flagger_ont_data_table.csv | grep ${SAMPLE} | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $22}')
        BAM=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam
        BAI=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam.bai
        COV_GZ=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.cov.gz
        TSV_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.stats.tsv
        BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
        BED_NOHAP_HAP1_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hap1.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
        BED_NOHAP_HAP2_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hap2.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
        BED_PRED_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_prediction.bed
        printf "${SAMPLE},${MAPPING_SUFFIX},${BAM},${BAI},${COV_GZ},${TSV_v1dot1},${BED_NOHAP_v1dot1},${BED_NOHAP_HAP1_v1dot1},${BED_NOHAP_HAP2_v1dot1},${BED_PRED_v1dot1}\n"
done < samples_list_batch1_jan_12_2025.txt  >> ${OUTPUT_TSV}


while read SAMPLE; do
	MAPPING_SUFFIX=$(cat ${BASE_DIR}/batch1/hmm_flagger/ont/hmm_flagger_ont_data_table.csv | grep ${SAMPLE} | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $23}')
	BAM=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam
	BAI=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam.bai
	COV_GZ=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.cov.gz
	TSV_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.stats.tsv
	BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	BED_NOHAP_HAP1_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hap1.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	BED_NOHAP_HAP2_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.hap2.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	BED_PRED_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_ont/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_prediction.bed
	printf "${SAMPLE},${MAPPING_SUFFIX},${BAM},${BAI},${COV_GZ},${TSV_v1dot1},${BED_NOHAP_v1dot1},${BED_NOHAP_HAP1_v1dot1},${BED_NOHAP_HAP2_v1dot1},${BED_PRED_v1dot1}\n"
done < samples_list_only_batch1.txt  >> ${OUTPUT_TSV}
