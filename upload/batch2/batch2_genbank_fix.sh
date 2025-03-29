# Sequence name, length, span(s), apparent source
# HG02738#2#h2tg000012l	98268417	98228921..98231355	vector/etc-not_cleaned

###############################################################################
## 					     HG02738#2: See If Hit Is Real                       ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/

mkdir -p check_contam
cd check_contam


## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch2/HG02738/analysis/assembly_cleanup_outputs/7ce6cdde-4e16-406a-b8a7-390b75554956/HG02738.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG02738.hap2_for_genbank.fa.gz HG02738.hap2_for_genbank.original.fa.gz

gunzip HG02738.hap2_for_genbank.original.fa.gz

samtools faidx  HG02738.hap2_for_genbank.original.fa \
	HG02738#2#h2tg000012l:98228921-98231355 \
	> HG02738#2#h2tg000012l_98228921_98231355.fa

## blasted it, seems to be EBV

## It's a 2k hit of EBV in the last part of the sequence...

## want to make sure that there arent telomeric repeats at the end of the sequence
seqtk telo HG02738.hap2_for_genbank.original.fa | grep "HG02738#2#h2tg000012l"

## nothing, so maybe the last 37k is all EBV. 
## minimap2 EBV onto contig...

samtools faidx  HG02738.hap2_for_genbank.original.fa\
	HG02738#2#h2tg000012l \
	> HG02738#2#h2tg000012l.fa

wget "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/402/265/GCF_002402265.1_ASM240226v1/GCF_002402265.1_ASM240226v1_genomic.fna.gz"

gunzip GCF_002402265.1_ASM240226v1_genomic.fna.gz 

minimap2 -x asm5 -t 8 \
	GCF_002402265.1_ASM240226v1_genomic.fna \
	HG02738#2#h2tg000012l.fa \
	> ebv_on_HG02738#2#h2tg000012l.paf

cat ebv_on_HG02738#2#h2tg000012l.paf
# HG02738#2#h2tg000012l	98268417	98240914	98268416	-	NC_007605.1	171823	132429	171757	27428	39351	60	tp:A:P	cm:i:2788	s1:i:25613	s2:i:521	dv:f:0.0001	rl:i:0
# HG02738#2#h2tg000012l	98268417	98222482	98238671	-	NC_007605.1	171823	7	15944	15853	16189	60	tp:A:P	cm:i:1602	s1:i:15811	s2:i:76	dv:f:0.0006	rl:i:0
# HG02738#2#h2tg000012l	98268417	98239300	98240891	-	NC_007605.1	171823	170181	171757	1568	1591	60	tp:A:P	cm:i:171	s1:i:1555	s2:i:1017	dv:f:0.0015	rl:i:0
# HG02738#2#h2tg000012l	98268417	98238743	98239815	-	NC_007605.1	171823	170181	171219	1030	1072	60	tp:A:P	cm:i:112	s1:i:1014	s2:i:506	dv:f:0.0014	rl:i:0
## so it's the last 45k of the contig; I will probably have to just mask that

###############################################################################
## 					     HG02738#2: See If Verkko Has It                     ##
###############################################################################

aws s3 cp s3://human-pangenomics/submissions/6807247E-4F71-45D8-AECE-9E5813BA1D9F--verkko-v2.2.1-release2_asms/HG02738/verkko-thic/HG02738.assembly.fasta.gz .

gunzip HG02738.assembly.fasta.gz

mv HG02738.assembly.fasta HG02738.assembly.verkko.fa

minimap2 -x asm5 -t 32 \
	GCF_002402265.1_ASM240226v1_genomic.fna \
	HG02738.assembly.verkko.fa \
	> ebv_on_HG02738.assembly.verkko.paf

cat ebv_on_HG02738.assembly.verkko.paf
# mat-0000006	101276965	1128289	1147139	+	NC_007605.1	171823	12900	31751	18788	18852	0	tp:A:P	cm:i:1875	s1:i:18788	s2:i:18788	dv:f:0.0001	rl:i:0
# mat-0000006	101276965	1128289	1147139	+	NC_007605.1	171823	15972	34823	18788	18852	0	tp:A:S	cm:i:1875	s1:i:18788	dv:f:0.0001	rl:i:0
# mat-0000006	101276965	1130490	1147139	+	NC_007605.1	171823	12029	28679	16566	16651	0	tp:A:S	cm:i:1648	s1:i:16566	dv:f:0.0001	rl:i:0
# mat-0000006	101276965	1128289	1144589	+	NC_007605.1	171823	19044	35344	16264	16300	0	tp:A:S	cm:i:1623	s1:i:16264	dv:f:0.0001	rl:i:0
# mat-0000006	101276965	1166578	1182767	+	NC_007605.1	171823	7	15944	15853	16189	60	tp:A:P	cm:i:1602	s1:i:15811	s2:i:3526	dv:f:0.0006	rl:i:0
# mat-0000006	101276965	1154681	1163801	+	NC_007605.1	171823	162607	171752	8438	9151	60	tp:A:P	cm:i:841	s1:i:8435	s2:i:1942	dv:f:0.0002	rl:i:0
# mat-0000006	101276965	1164372	1166560	+	NC_007605.1	171823	169663	171812	2081	2189	60	tp:A:P	cm:i:224	s1:i:2055	s2:i:1562	dv:f:0.0012	rl:i:0
# mat-0000006	101276965	1163849	1165411	+	NC_007605.1	171823	170216	171757	1505	1562	60	tp:A:P	cm:i:164	s1:i:1495	s2:i:326	dv:f:0.0016	rl:i:0
# mat-0000016	106489939	14457980	14458152	+	NC_007605.1	171823	83066	83246	113	180	60	tp:A:P	cm:i:9	s1:i:111	s2:i:0dv:f:0.0105	rl:i:0

rm HG02738.assembly.verkko.fa

## so it's in both assemblies! I will still trim because it's at the end
## of the contig in the case of hifiasm and this may be a cell line artifact

###############################################################################
## 					      HG02738#2: Trim Sequence Off                       ##
###############################################################################

## Trim based on Minimap2 mapping of EBV onto contig...
# HG02738#2#h2tg000012l:98222482-98268416

## mask adapter sequence
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02738.hap2_for_genbank.original.fa \
    trim "HG02738#2#h2tg000012l:98222482-98268417" \
    HG02738.hap2_for_genbank.fa


## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02738.hap2_for_genbank.original.fa
# Total Bases: 3038268697
# Total Contigs: 65

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02738.hap2_for_genbank.fa
# Total Bases: 3038222761
# Total Contigs: 65


## check trim
samtools faidx  HG02738.hap2_for_genbank.fa
cat HG02738.hap2_for_genbank.fa.fai | grep "HG02738#2#h2tg000012l"
# HG02738#2#h2tg000012l-3trim	98222481	2344430594	60	61

## gzip for upload...
pigz HG02738.hap2_for_genbank.fa &

rm HG02738.hap2_for_genbank.original.fa HG02738.hap2_for_genbank.original.fa.fai


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/check_contam

mkdir batch2_fixes_genbank_upload

mv HG02738.hap2_for_genbank.fa.gz batch2_fixes_genbank_upload/

cp \
	/private/groups/hprc/genbank_upload/batch2/HG02738/analysis/assembly_cleanup_outputs/d823db13-f7db-4279-b1a8-a56c52758a32/HG02738.hap1_for_genbank.fa.gz \
	batch2_fixes_genbank_upload/

 
ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch2_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch2_fixes


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################


cd /private/groups/hprc/genbank_upload/batch2/check_contam

mkdir -p batch2_fixes_s3_upload/NA19159/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch2_fixes_genbank_upload/NA19159.hap2_for_genbank.fa.gz \
	batch2_fixes_s3_upload/NA19159/assemblies/freeze_2/assembly_pipeline/ncbi_upload/NA19159.hap2_for_genbank_fixed.fa.gz


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch2_fixes_s3_upload \
    &>>batch2_s3_upload_fixes.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################