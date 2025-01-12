cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/hifi

touch csv2tab && chmod u+x csv2tab

#Add to it
cat <<EOF > csv2tab
#!/usr/bin/env python
import csv, sys
csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))
EOF

OUTPUT_TSV="hmm_flagger_hifi_data_table.output_s3.csv"
BASE="https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC"
printf "sample_id,mapping_info,bam_link,bai_link,cov_gz_link,hmm_flagger_v1.1_stats_tsv_link,hmm_flagger_v1.1_nohap_bed_link,hmm_flagger_v1.1_prediction_bed_link\n" > ${OUTPUT_TSV}


while read line; do
	SAMPLE=$(echo $line | ./csv2tab | awk -v RS='\r\n'  -F'\t' '{print $1}')
	MAPPING_SUFFIX="hifi_DC_minimap2_2.28"
	if [[ ${SAMPLE} == "sample_id" ]];then
		continue
	fi
	BAM=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam
	BAI=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam.bai
	COV_GZ=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.cov.gz
	TSV_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.stats.tsv
	BED_NOHAP_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/${SAMPLE}.hmm_flagger_v1.1.0.hmm_flagger.no_Hap.bed
	BED_PRED_v1dot1=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.1.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_prediction.bed
	printf "${SAMPLE},${MAPPING_SUFFIX},${BAM},${BAI},${COV_GZ},${TSV_v1dot1},${BED_NOHAP_v1dot1},${BED_PRED_v1dot1}\n"
done < hmm_flagger_hifi_data_table.csv >> ${OUTPUT_TSV}
