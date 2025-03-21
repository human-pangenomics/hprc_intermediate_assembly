cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/hmm_flagger_tables_march_18_2025/hifi

touch csv2tab && chmod u+x csv2tab

#Add to it
cat <<EOF > csv2tab
#!/usr/bin/env python
import csv, sys
csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))
EOF

OUTPUT_TSV="hmm_flagger_hifi_data_table.output_s3.csv"
BASE="https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC"

printf "sample_id,mapping_info,bam,bai,cov_gz,stats_tsv,conservative_stats_tsv,prediction_nohap_diploid_bed,prediction_nohap_hap1_bed,prediction_nohap_hap2_bed,prediction_diploid_bed,prediction_conservative_nohap_diploid_bed,prediction_conservative_nohap_hap1_bed,prediction_conservative_nohap_hap2_bed,prediction_conservative_diploid_bed,mappable_hap1_bed,mappable_hap2_bed,bigwig,high_mapq_bigwig,high_clip_bigwig\n" > ${OUTPUT_TSV}

cat /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/rerun_march_01_2025/hmm_flagger/hifi/hmm_flagger_hifi_data_table.csv | \
        grep -v -F -f ../samples_swapped_hap.txt | \
        grep -v sample_id  | \
	./csv2tab | \
	awk -F'\t' '{print $1"\t"$2}' > samples_list.txt

cat /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch3/hmm_flagger/hifi/hmm_flagger_hifi_data_table.csv | \
        grep -v sample_id | \
	./csv2tab | \
	awk -F'\t' '{print $1"\thifi_minimap2_2.28"}' >> samples_list.txt

# download BED files, separate them by haplotypes, upload them to the related s3 bucket
cat samples_list.txt | while read line; do
	SAMPLE=$(echo $line | awk '{print $1}')
	MAPPING_SUFFIX=$(echo $line | awk '{print $2}')
	BAM=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam
	BAI=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/read_alignments/hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.bam.bai
	COV_GZ=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.cov.gz
	TSV=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.stats.tsv
	CONSER_TSV=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.augmented.conservative.stats.tsv
	NOHAP_DIP_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.canonical.no_Hap.bed
	NOHAP_HAP1_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.canonical.no_Hap.hap1.bed
	NOHAP_HAP2_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.canonical.no_Hap.hap2.bed
	FULL_DIP_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.bed
	CONSER_NOHAP_DIP_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.conservative.canonical.no_Hap.bed
	CONSER_NOHAP_HAP1_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.conservative.canonical.no_Hap.hap1.bed
	CONSER_NOHAP_HAP2_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.conservative.canonical.no_Hap.hap2.bed
	CONSER_FULL_DIP_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.hmm_flagger_v1.2.0_prediction.conservative.bed
	MAPPABLE_HAP1_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.mapq_ge_10.cov_ge_4.mappable.hap1.bed
	MAPPABLE_HAP2_BED=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.mapq_ge_10.cov_ge_4.mappable.hap2.bed
	BIGWIG=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.bigwig
	HIGH_MAPQ_BIGWIG=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.high_mapq.bigwig
	HIGH_CLIP_BIGWIG=${BASE}/${SAMPLE}/hprc_r2/assembly_qc/hmm_flagger/v1.2.0_hifi/${SAMPLE}.${MAPPING_SUFFIX}.corrected.downsample_1.0.high_clip.bigwig
	printf "${SAMPLE},${MAPPING_SUFFIX},${BAM},${BAI},${COV_GZ},${TSV},${CONSER_TSV},${NOHAP_DIP_BED},${NOHAP_HAP1_BED},${NOHAP_HAP2_BED},${FULL_DIP_BED},${CONSER_NOHAP_DIP_BED},${CONSER_NOHAP_HAP1_BED},${CONSER_NOHAP_HAP2_BED},${CONSER_FULL_DIP_BED},${MAPPABLE_HAP1_BED},${MAPPABLE_HAP2_BED},${BIGWIG},${HIGH_MAPQ_BIGWIG},${HIGH_CLIP_BIGWIG}\n"
done >> ${OUTPUT_TSV}

