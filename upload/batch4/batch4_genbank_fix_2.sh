## One sequence has a terminal N for some reason...
##lcl|HG02155#2#h2tg000098c:BIOSEQ	 lcl|HG02155#2#h2tg000098c: delta, dna len= 7096715

###############################################################################
## 					     	Pull Sequences Identified                        ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/

mkdir check_contam_2
cd check_contam_2

###############################################################################
## 					            	HG02155                                  ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch4/HG02155/analysis/assembly_cleanup_outputs/c8ece15b-40fc-4b0b-924a-8de0ba2f2964/HG02155.hap2_for_genbank.fa.gz \
	.

## check problem...
zcat HG02155.hap2_for_genbank.fa.gz | grep -A 4 'HG02155#2#h2tg000098c'
# >HG02155#2#h2tg000098c
# NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
# NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNCATCATCAAATGGAATCAAA
# AATAACCATCATCAATTGCTATTGAATGGAATTGTCATCAAATGGAATTCAAAGGAATCA
# TCATCAAATGGAACCGAATGGAATCCTCATTGAATGGAAATGAAAGGGGTCATCATCTAA

## funky. this must have been a circular contig that was scaffolded then
## the circle was broken on the N's?

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG02155.hap2_for_genbank.fa.gz HG02155.hap2_for_genbank.original.fa.gz

gunzip HG02155.hap2_for_genbank.original.fa.gz

## trim off the first 100bp...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02155.hap2_for_genbank.original.fa \
    trim "HG02155#2#h2tg000098c:1-100" \
    HG02155.hap2_for_genbank.fa

## check after trimming
cat HG02155.hap2_for_genbank.fa | grep -A 4 'HG02155#2#h2tg000098c'


## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02155.hap2_for_genbank.original.fa
# Total Bases: 3032908106
# Total Contigs: 82

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02155.hap2_for_genbank.fa
# Total Bases: 3032908006
# Total Contigs: 82

## gzip for upload...
gzip HG02155.hap2_for_genbank.fa

###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/check_contam_2

mkdir batch4_fixes_genbank_upload_2

mv HG02155.hap2_for_genbank.fa.gz batch4_fixes_genbank_upload_2/

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch4_fixes_genbank_upload_2 \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch4_fixes

###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/check_contam_2

mkdir -p batch4_fixes_s3_upload/HG02155/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch4_fixes_genbank_upload_2/HG02155.hap2_for_genbank.fa.gz \
	batch4_fixes_s3_upload/HG02155/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG02155.hap2_for_genbank_fixed.fa.gz

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch4_fixes_s3_upload \
    &>>batch4_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################