# Exclude:
# Sequence name, length, apparent source
# HG03470#1#h1tg000032l	166107	mitochondrion-not_cleaned

# Exclude:
# Sequence name, length, apparent source
# HG03470#2#h2tg000032l	166107	mitochondrion-not_cleaned


###############################################################################
## 					     	Pull Sequences Identified                        ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch5/

mkdir check_contam
cd check_contam

## HG03470#1
## check that the contig is actually all mito: it sure is
## my filtering missed it because this mito is so big.
cat /private/groups/hprc/genbank_upload/batch5/HG03470/analysis/assembly_cleanup_outputs/c858a5fd-0d11-4c8c-821b-c6cb467bf9fc/HG03470.hap1.mito_blast_out.txt |
	grep "h1tg000032l" | sort -k7,7n
# h1tg000032l     NC_012920.1     99.556  9019    40      0       1       9019    7551    16569   0.0     16434   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       9020    25586   1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       25587   42153   1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.493  16570   80      3       42154   58720   1       16569   0.0     30131   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       58721   75287   1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.505  16570   78      3       75288   91854   1       16569   0.0     30142   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       91855   108421  1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.505  16570   78      3       108422  124988  1       16569   0.0     30142   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       124989  141555  1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.499  16570   79      3       141556  158122  1       16569   0.0     30136   166107  16569
# h1tg000032l     NC_012920.1     99.449  7988    40      3       158123  166107  1       7987    0.0     14504   166107  16569


## HG03470#2
## check that the contig is actually all mito: it sure is
## my filtering missed it because this mito is so big.
cat /private/groups/hprc/genbank_upload/batch5/HG03470/analysis/assembly_cleanup_outputs/71f8d459-e70e-44ec-b99b-34f9f92abe81/HG03470.hap2.mito_blast_out.txt \
	| grep "h2tg000032l" | sort -k7,7n
# h2tg000032l     NC_012920.1     99.556  9019    40      0       1       9019    7551    16569   0.0     16434   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       9020    25586   1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       25587   42153   1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.493  16570   80      3       42154   58720   1       16569   0.0     30131   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       58721   75287   1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.505  16570   78      3       75288   91854   1       16569   0.0     30142   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       91855   108421  1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.505  16570   78      3       108422  124988  1       16569   0.0     30142   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       124989  141555  1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.499  16570   79      3       141556  158122  1       16569   0.0     30136   166107  16569
# h2tg000032l     NC_012920.1     99.449  7988    40      3       158123  166107  1       7987    0.0     14504   166107  16569

## looks like the same contig got assigned to both haplotypes


###############################################################################
## 					  	HG03470#1: Remove Extra MT Contig                    ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch5/HG03470/analysis/assembly_cleanup_outputs/1a686054-c104-474c-9503-c38626976b9f/HG03470.hap1_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG03470.hap1_for_genbank.fa.gz HG03470.hap1_for_genbank.original.fa.gz

gunzip HG03470.hap1_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG03470.hap1_for_genbank.original.fa \
    remove "HG03470#1#h1tg000032l" \
    HG03470.hap1_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03470.hap1_for_genbank.original.fa
Total Bases: 3042313597
Total Contigs: 95

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03470.hap1_for_genbank.fa
Total Bases: 3042147490
Total Contigs: 94

## gzip for upload...
gzip HG03470.hap1_for_genbank.fa


###############################################################################
## 					  	HG03470#2: Remove Extra MT Contig                    ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch5/HG03470/analysis/assembly_cleanup_outputs/be384f49-7929-41fd-bfbb-b8a0fb538adf/HG03470.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG03470.hap2_for_genbank.fa.gz HG03470.hap2_for_genbank.original.fa.gz

gunzip HG03470.hap2_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG03470.hap2_for_genbank.original.fa \
    remove "HG03470#2#h2tg000032l" \
    HG03470.hap2_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03470.hap2_for_genbank.original.fa
# Total Bases: 3042797612
# Total Contigs: 70

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03470.hap2_for_genbank.fa
# Total Bases: 3042631505
# Total Contigs: 69

## gzip for upload...
gzip HG03470.hap2_for_genbank.fa


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch5/check_contam

mkdir batch5_fixes_genbank_upload

mv HG03470.hap1_for_genbank.fa.gz batch5_fixes_genbank_upload/
mv HG03470.hap2_for_genbank.fa.gz batch5_fixes_genbank_upload/

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch5_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch5_fixes

###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch5/check_contam

mkdir -p batch5_fixes_s3_upload/HG03470/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch5_fixes_genbank_upload/HG03470.hap1_for_genbank.fa.gz \
	batch5_fixes_s3_upload/HG03470/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG03470.hap1_for_genbank_fixed.fa.gz

cp \
	batch5_fixes_genbank_upload/HG03470.hap2_for_genbank.fa.gz \
	batch5_fixes_s3_upload/HG03470/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG03470.hap2_for_genbank_fixed.fa.gz

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch5_fixes_s3_upload \
    &>>batch5_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################