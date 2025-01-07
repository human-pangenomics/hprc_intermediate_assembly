cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch1/hmm_flagger/ont


touch csv2tab && chmod u+x csv2tab

#Add to it

cat <<EOF > csv2tab
#!/usr/bin/env python
import csv, sys
csv.writer(sys.stdout, dialect='excel-tab').writerows(csv.reader(sys.stdin))
EOF

printf "sample_id\tmapping_info\tbam_link\tbai_link\n" > ont_bam_table.tsv

cat hmm_flagger_ont_data_table.csv | \
    grep -v sample_id | \
    ./csv2tab  | \
    awk -v RS='\r\n' -F'\t' '{print $1"\t"$23"\t""https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC/"$1"/hprc_r2/assembly_qc/read_alignments/ont/"$1"."$23".corrected.bam\thttps://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/ca366a13-5bad-487b-8a57-97344e9aa0e4--HPRC_RELEASE_2_SUPPLEMENTARY_ASSEMBLY_QC/"$1"/hprc_r2/assembly_qc/read_alignments/ont/"$1"."$23".corrected.bam.bai"}' >> ont_bam_table.tsv
