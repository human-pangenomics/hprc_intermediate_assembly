# Trim:
# Sequence name, length, span(s), apparent source
# HG03816#2#h2tg000042l	1046361	929168..929250	adaptor:NGB00972.1-not_cleaned

# Trim:
# Sequence name, length, span(s), apparent source
# HG00706#1#h1tg000011l	105123810	20774367..20774444	adaptor:NGB00972.1-not_cleaned


###############################################################################
## 					     HG03816#2: Trim Adapter                             ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch6/

mkdir check_contam
cd check_contam


## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch6/HG03816/analysis/assembly_cleanup_outputs/ea4fbabe-b26f-41bd-a1b8-55fec71a9c3c/HG03816.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG03816.hap2_for_genbank.fa.gz HG03816.hap2_for_genbank.original.fa.gz

gunzip HG03816.hap2_for_genbank.original.fa.gz


samtools faidx  HG03816.hap2_for_genbank.original.fa HG03816#2#h2tg000042l:929168-929250

# >HG03816#2#h2tg000042l:929168-929250
# TCTCTCTCAACAACAACAACGGGAGGAGGAGGAAAAGAGAGAGACTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAG

# >gnl|uv|NGB00972.1:1-45 Pacific Biosciences Blunt Adapter
# ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT

#  TCTCTCTCAACAACAACAACGGGAGGAGGAGGAAAAGAGAGAGACTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAG
#  |||||||||||||||||||||| ||||||||||||||||||||| 
# ATCTCTCTCAACAACAACAACGG-AGGAGGAGGAAAAGAGAGAGAATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTT (hairpin)

## rest of the hit is only so so, but that's ok

## mask adapter sequence
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG03816.hap2_for_genbank.original.fa \
    mask "HG03816#2#h2tg000042l:929168-929250" \
    HG03816.hap2_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03816.hap2_for_genbank.original.fa
# Total Bases: 3021560841
# Total Contigs: 71

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03816.hap2_for_genbank.fa
# Total Bases: 3021560841
# Total Contigs: 71

## check masking
samtools faidx  HG03816.hap2_for_genbank.fa HG03816#2#h2tg000042l:929168-929250
# >HG03816#2#h2tg000042l:929168-929250
# NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
# NNNNNNNNNNNNNNNNNNNNNNN

## gzip for upload...
pigz HG03816.hap2_for_genbank.fa &

rm HG03816.hap2_for_genbank.original.fa HG03816.hap2_for_genbank.original.fa.fai


###############################################################################
## 					     HG00706#1: Trim Adapter                             ##
###############################################################################


## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch6/HG00706/analysis/assembly_cleanup_outputs/9e0c15cb-c667-4034-8330-b9652175fe41/HG00706.hap1_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG00706.hap1_for_genbank.fa.gz HG00706.hap1_for_genbank.original.fa.gz

gunzip HG00706.hap1_for_genbank.original.fa.gz


samtools faidx  HG00706.hap1_for_genbank.original.fa HG00706#1#h1tg000011l:20774367-20774444

# >HG00706#1#h1tg000011l:20774367-20774444
# TCTCTCTCAACAACAACAAACGGAGGAGGAGGAAAAAGAGAGAGATTCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTT

# >gnl|uv|NGB00972.1:1-45 Pacific Biosciences Blunt Adapter
# ATCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTTGAGAGAGAT

#  TCTCTCTCAACAACAACAAACGGAGGAGGAGGAAAAAGAGAGAGATTCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTT
# ATCTCTCTCAACAACAACAA-CGGAGGAGGAGGAAAAGAGAGAGAA-TCTCTCTCTTTTCCTCCTCCTCCGTTGTTGTTGTT

## mask adapter sequence
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG00706.hap1_for_genbank.original.fa \
    mask "HG00706#1#h1tg000011l:20774367-20774444" \
    HG00706.hap1_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG00706.hap1_for_genbank.original.fa
# Total Bases: 2932473439
# Total Contigs: 96
## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG00706.hap1_for_genbank.fa
# Total Bases: 2932473439
# Total Contigs: 96

## check masking
samtools faidx  HG00706.hap1_for_genbank.fa HG00706#1#h1tg000011l:20774367-20774444
# >HG00706#1#h1tg000011l:20774367-20774444
# NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
# NNNNNNNNNNNNNNNNNN

## gzip for upload...
pigz HG00706.hap1_for_genbank.fa &

rm HG00706.hap1_for_genbank.original.fa HG00706.hap1_for_genbank.original.fa.fai

###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch6/check_contam

mkdir batch6_fixes_genbank_upload

mv HG03816.hap2_for_genbank.fa.gz batch6_fixes_genbank_upload/
mv HG00706.hap1_for_genbank.fa.gz batch6_fixes_genbank_upload/

cp \
	/private/groups/hprc/genbank_upload/batch6/HG03816/analysis/assembly_cleanup_outputs/0bb344f7-c5bf-41dc-a3c0-8c5af997b702/HG03816.hap1_for_genbank.fa.gz \
	batch6_fixes_genbank_upload/
cp \
	/private/groups/hprc/genbank_upload/batch6/HG00706/analysis/assembly_cleanup_outputs/35f6ca67-3802-4a27-90da-8deaabdf2679/HG00706.hap2_for_genbank.fa.gz \
	batch6_fixes_genbank_upload/
 

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch6_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch6_fixes

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch6_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch6_fixes_resubmit

###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

mkdir -p batch6_fixes_s3_upload/HG00706/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
mkdir -p batch6_fixes_s3_upload/HG03816/assemblies/freeze_2/assembly_pipeline/ncbi_upload/


cp \
    batch6_fixes_genbank_upload/HG00706.hap1_for_genbank.fa.gz \
    batch6_fixes_s3_upload/HG00706/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG00706.hap1_for_genbank_fixed.fa.gz

cp \
	batch6_fixes_genbank_upload/HG03816.hap2_for_genbank.fa.gz \
	batch6_fixes_s3_upload/HG03816/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG03816.hap2_for_genbank_fixed.fa.gz


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch6_fixes_s3_upload \
    &>>batch6_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################