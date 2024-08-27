
cd /private/groups/hprc/genbank_upload/batch1


###############################################################################
##                            Run Cleanup WDL                                ##
###############################################################################

## copy in polishing results
cp /private/groups/hprc/hprc_intermediate_assembly/polishing/batch2/apply_GQ_filter/hprc_polishing_QC_k31/intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv ./

cat <<EOF > assembly_cleanup_input_mapping.csv
input,type,value
assembly_cleanup_wf.sample_id,scalar,\$input.sample_id
assembly_cleanup_wf.hap1_fasta,scalar,\$input.polishedGQFilterAsmHap1
assembly_cleanup_wf.hap2_fasta,scalar,\$input.polishedGQFilterAsmHap2
assembly_cleanup_wf.hifi_reads,array,\$input.hifi
assembly_cleanup_wf.seq_info,scalar,/private/groups/hprc/ref_files/fcs/all.seq_info.tsv.gz
assembly_cleanup_wf.blast_div,scalar,/private/groups/hprc/ref_files/fcs/all.blast_div.tsv.gz
assembly_cleanup_wf.manifest,scalar,/private/groups/hprc/ref_files/fcs/all.manifest
assembly_cleanup_wf.taxa,scalar,/private/groups/hprc/ref_files/fcs/all.taxa.tsv
assembly_cleanup_wf.metaJSON,scalar,/private/groups/hprc/ref_files/fcs/all.meta.jsonl
assembly_cleanup_wf.GXS,scalar,/private/groups/hprc/ref_files/fcs/all.gxs
assembly_cleanup_wf.GXI,scalar,/private/groups/hprc/ref_files/fcs/all.gxi
assembly_cleanup_wf.related_mito_fasta,scalar,/private/groups/hprc/ref_files/mito/rcrs_reference/NC_012920.1.fasta
assembly_cleanup_wf.ncbi_mito_blast_db,scalar,/private/groups/hprc/ref_files/mito/ncbi_mito_blast_db_v1.1.tar.gz
assembly_cleanup_wf.related_mito_genbank,scalar,/private/groups/hprc/ref_files/mito/rcrs_reference/NC_012920.1.gb
EOF

mkdir input_jsons
cd input_jsons

## create input jsons for assembly cleanup
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv \
     --field_mapping ../assembly_cleanup_input_mapping.csv \
     --workflow_name assembly_cleanup


cd ..
mkdir -p slurm_logs

## run assembly cleanup
sbatch \
     --job-name=HPRC-cleanup \
     --array=[1-10] \
     --partition=long \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/workflows/assembly_cleanup.wdl \
     --sample_csv intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_assembly_cleanup.json' 

## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table intermAssembl_batch1_sample_table_20231204_WUSTLonly_s3_mira_polishing_batch2_noTopUp_updated.filterVcf.polished.csv \
    --output_data_table batch1_genbank_upload_prep_outputs.csv  \
    --json_location '{sample_id}_assembly_cleanup_outputs.json'


###############################################################################
##                           Pull Assembly Cleanup Stats                     ##
###############################################################################

mkdir asm_cleanup_stats 
cd asm_cleanup_stats

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_asm_cleanup_stats.py \
    --input_csv ../batch1_genbank_upload_prep_outputs.csv \
    --output_prefix hprc_int_asm_batch1

###############################################################################
##                  Quick Manual QC Since This Is Our First Run              ##
###############################################################################

mkdir check
cd check

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_comparison.py \
    --fasta_fp /private/groups/hprc/polishing/batch2/apply_GQ_filter/HG00408/./applyPolish_pat_outputs/HG00408_hap1.polished.fasta \
    --fasta2_fp /private/groups/hprc/genbank_upload/batch1/HG00408/analysis/assembly_cleanup_outputs/9ea96ac0-73ec-45cd-9f3d-47076e0013a3/HG00408.hap1_for_genbank.fa.gz \
    --fasta1_name HG00408_hap1_polished \
    --fasta2_name HG00408_hap1_genbank

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_comparison.py \
    --fasta_fp /private/groups/hprc/polishing/batch2/apply_GQ_filter/HG00408/./applyPolish_mat_outputs/HG00408_hap2.polished.fasta \
    --fasta2_fp /private/groups/hprc/genbank_upload/batch1/HG00408/analysis/assembly_cleanup_outputs/65203c01-c016-4f06-99d7-d56d8874f755/HG00408.hap2_for_genbank.fa.gz \
    --fasta1_name HG00408_hap2_polished \
    --fasta2_name HG00408_hap2_genbank

## everything looks roughly as expected:
## only pickup mito in hap2
## dropped: contigs < 50kb, mito contigs, GX identified contigs

mkdir mito_plots
cd mito_plots

## quickly check two mito alignment plots to see if anything funky is happening
## doesn't look wild, but this isn't a great check...
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/mito_alignment_plot.py \
    --input_paf /private/groups/hprc/genbank_upload/batch1/HG00408/analysis/assembly_cleanup_outputs/6b0ee8e5-f80f-4ac2-a496-516915e5d74d/HG00408_aligned_to_concat_mito.paf \
    --output_prefix HG00408_mito_plot_1

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/mito_alignment_plot.py \
    --input_paf /private/groups/hprc/genbank_upload/batch1/HG02258/analysis/assembly_cleanup_outputs/d4c4a848-d84d-4d4d-810c-cbf2d0fda302/HG02258_aligned_to_concat_mito.paf \
    --output_prefix HG02258_mito_plot_1


###############################################################################
##                  Soft Link Assemblies To Upload Folder                    ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch1/

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_folder.py \
    --data_table_csv batch1_genbank_upload_prep_outputs.csv \
    --columns_to_link hap1_output_fasta_gz hap2_output_fasta_gz \
    --target_dir batch1_genbank_upload_pt1

## remove HG01975 until we figure out if it has a misjoin or a robertsonian
## translocation with chr13/chr21 q-arms
rm batch1_genbank_upload_pt1/HG01975.hap*_for_genbank.fa.gz


###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch1_genbank_upload_pt1 \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch1_pt1


###############################################################################
##                                   DONE                                    ##
###############################################################################


