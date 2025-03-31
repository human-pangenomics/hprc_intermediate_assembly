# Trim:
# Sequence name, length, span(s), apparent source
# NA19159#2#h2tg000004l	91520858	91501816..91504250	vector/etc-not_cleaned

###############################################################################
## 					     NA19159#2: See If Hit Is Real                       ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch7/

mkdir -p check_contam
cd check_contam


## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch7/NA19159/analysis/assembly_cleanup_outputs/c36d5f45-53cb-485d-b260-425ae3f75c60/NA19159.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv NA19159.hap2_for_genbank.fa.gz NA19159.hap2_for_genbank.original.fa.gz

gunzip NA19159.hap2_for_genbank.original.fa.gz

samtools faidx  NA19159.hap2_for_genbank.original.fa \
	NA19159#2#h2tg000004l:91501816-91504250 \
	> NA19159#2#h2tg000004l_91501816_91504250.fa

## blasted it, seems to be EBV

## It's a 2k hit of EBV in the last 19kb of the sequence...

## want to make sure that there arent telomeric repeats at the end of the sequence
seqtk telo NA19159.hap2_for_genbank.original.fa | grep "NA19159#2#h2tg000004l"

## nothing, so maybe the last 19k is all EBV. Check that now.
samtools faidx  NA19159.hap2_for_genbank.original.fa \
	NA19159#2#h2tg000004l:91501816-91520858 \
	> NA19159#2#h2tg000004l_91501816_91520858.fa
## yup, that's all EBV...

## see where it starts...
## minimap2 EBV onto contig...

samtools faidx  NA19159.hap2_for_genbank.original.fa \
	NA19159#2#h2tg000004l \
	> NA19159#2#h2tg000004l.fa

wget "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/402/265/GCF_002402265.1_ASM240226v1/GCF_002402265.1_ASM240226v1_genomic.fna.gz"

minimap2 -x asm5 -t 8 \
	GCF_002402265.1_ASM240226v1_genomic.fna \
	NA19159#2#h2tg000004l.fa \
	> ebv_on_NA19159#2#h2tg000004l.paf

cat ebv_on_NA19159#2#h2tg000004l.paf
# NA19159#2#h2tg000004l	91520858	91498455	91511566	-	NC_007605.1	171823	7	12866	12847	13111	60	tp:A:P	cm:i:1306	s1:i:12805	s2:i:76	dv:f:0.0007	rl:i:0
# NA19159#2#h2tg000004l	91520858	91511638	91520856	-	NC_007605.1	171823	161999	171219	9192	9220	60	tp:A:P	cm:i:940	s1:i:9191	s2:i:0	dv:f:0.0002	rl:i:0

## so it's the last 22401 of the contig; I will probably have to just mask that


###############################################################################
## 					     NA19159#2: See If Verkko Has It                     ##
###############################################################################

aws s3 cp s3://human-pangenomics/submissions/6807247E-4F71-45D8-AECE-9E5813BA1D9F--verkko-v2.2.1-release2_asms/NA19159/verkko-hi-c/NA19159.assembly.fasta.gz .

gunzip NA19159.assembly.fasta.gz

mv NA19159.assembly.fasta NA19159.assembly.verkko.fa

minimap2 -x asm5 -t 32 \
	GCF_002402265.1_ASM240226v1_genomic.fna \
	NA19159.assembly.verkko.fa \
	> ebv_on_NA19159.assembly.verkko.paf

cat ebv_on_NA19159.assembly.verkko.paf
## empty, so Verkko doesn't have this hit

rm NA19159.assembly.verkko.fa


###############################################################################
## 					      NA19159#2: Trim Sequence Off                       ##
###############################################################################

## Trim based on Minimap2 mapping of EBV onto contig...
# NA19159#2#h2tg000004l	91520858		91511566	-	NC_007605.1	171823	7	12866	12847	13111	60	tp:A:P	cm:i:1306	s1:i:12805	s2:i:76	dv:f:0.0007	rl:i:0
# NA19159#2#h2tg000004l	91520858	91511638		-	NC_007605.1	171823	161999	171219	9192	9220	60	tp:A:P	cm:i:940	s1:i:9191	s2:i:0	dv:f:0.0002	rl:i:0


## mask adapter sequence
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	NA19159.hap2_for_genbank.original.fa \
    trim "NA19159#2#h2tg000004l:91498455-91520858" \
    NA19159.hap2_for_genbank.fa


## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA19159.hap2_for_genbank.original.fa
# Total Bases: 3020988604
# Total Contigs: 69

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA19159.hap2_for_genbank.fa
# Total Bases: 3020966200
# Total Contigs: 69

## check trim
samtools faidx  NA19159.hap2_for_genbank.fa
# cat NA19159.hap2_for_genbank.fa.fai | grep "NA19159#2#h2tg000004l"
# NA19159#2#h2tg000004l-3trim	91498454	355202526	60	61

## gzip for upload...
pigz NA19159.hap2_for_genbank.fa &

rm NA19159.hap2_for_genbank.original.fa NA19159.hap2_for_genbank.original.fa.fai


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch7/check_contam

mkdir batch7_fixes_genbank_upload

mv NA19159.hap2_for_genbank.fa.gz batch7_fixes_genbank_upload/

cp \
	/private/groups/hprc/genbank_upload/batch7/NA19159/analysis/assembly_cleanup_outputs/41736067-f649-4d22-9ae2-34f40f0b5414/NA19159.hap1_for_genbank.fa.gz \
	batch7_fixes_genbank_upload/

 
ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch7_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch7_fixes


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################


cd /private/groups/hprc/genbank_upload/batch7/check_contam

mkdir -p batch7_fixes_s3_upload/NA19159/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch7_fixes_genbank_upload/NA19159.hap2_for_genbank.fa.gz \
	batch7_fixes_s3_upload/NA19159/assemblies/freeze_2/assembly_pipeline/ncbi_upload/NA19159.hap2_for_genbank_fixed.fa.gz


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch7_fixes_s3_upload \
    &>>batch7_s3_upload_fixes.upload.stderr


###############################################################################
##                                   DONE                                    ##
###############################################################################