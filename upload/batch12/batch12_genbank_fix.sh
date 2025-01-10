# Trim:
# Sequence name, length, span(s), apparent source
# NA20806#1#haplotype1-0000027	72459159	55..107	adaptor:multiple

###############################################################################
## 					     NA19240#1: Trim Adapter                             ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12/

mkdir check_contam
cd check_contam


## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch12/NA20806/analysis/assembly_cleanup_outputs/e838b6a8-7385-48fe-8a6e-44d2f3f6a2e6/NA20806.hap1_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv NA20806.hap1_for_genbank.fa.gz NA20806.hap1_for_genbank.original.fa.gz

gunzip NA20806.hap1_for_genbank.original.fa.gz


samtools faidx  NA20806.hap1_for_genbank.original.fa NA20806#1#haplotype1-0000027:0-107

# >NA20806#1#haplotype1-0000027:0-107
# ACGTTTGGTTTTGTATTGTACTTCGTTCAGTTGTATGAATTTTTGGGTGTTTAACCGTTT
# TCGCATTTATCGTGAAACGCTTTCGCGTTTTTCGTGCGCCGCTTCAG

# Oxford Nanopore Technologies Rapid Adapter RAP (pulled from porechop)
# GTTTTCGCATTTATCGTGAAACGCTTTCGCGTTTTTCGTGCGCCGCTTCA


## take a look:
# ACGTTTGGTTTTGTATTGTACTTCGTTCAGTTGTATGAATTTTTGGGTGTTTAACCGTTTTCGCATTTATCGTGAAACGCTTTCGCGTTTTTCGTGCGCCGCTTCAG
# 														  ||||||||||||||||||||||||||||||||||||||||||||||||||
#                                                         GTTTTCGCATTTATCGTGAAACGCTTTCGCGTTTTTCGTGCGCCGCTTCA


## def. a real hit. trim out the first 107 bases.

## trim adapter sequence
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	NA20806.hap1_for_genbank.original.fa \
    trim "NA20806#1#haplotype1-0000027:1-107" \
    NA20806.hap1_for_genbank.fa


## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA20806.hap1_for_genbank.original.fa
# Total Bases: 2897340245
# Total Contigs: 31

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA20806.hap1_for_genbank.fa
# Total Bases: 2897340138
# Total Contigs: 31

## gzip for upload...
pigz NA20806.hap1_for_genbank.fa &


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12/check_contam

mkdir batch12_fixes_genbank_upload

mv NA20806.hap1_for_genbank.fa.gz batch12_fixes_genbank_upload/

cp \
	/private/groups/hprc/genbank_upload/batch12/NA20806/analysis/assembly_cleanup_outputs/e9dc562e-9707-4628-b491-6a998a85416d/NA20806.hap2_for_genbank.fa.gz \
	batch12_fixes_genbank_upload/

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch12_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch12_fixes


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch12/check_contam

mkdir -p batch12_fixes_s3_upload/NA20806/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch12_fixes_genbank_upload/NA20806.hap1_for_genbank.fa.gz \
	batch12_fixes_s3_upload/NA20806/assemblies/freeze_2/assembly_pipeline/ncbi_upload/NA20806.hap1_for_genbank_fixed.fa.gz


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch12_fixes_s3_upload \
    &>>batch12_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################