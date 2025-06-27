# Overview

Assemblies are indexed in `assemblies_pre_release_v0.6.1.index.csv`. See the documentation below for more information about the assemblies and the assembly index file.

The rest of the data in Release 2 are organized in folder for each data type:
* **Sample** metadata is included in the `/sample` folder.
* **Sequencing data** index files are included in the `/sequencing_data` folder
* **Assembly QC** index files are included in the `/assembly_qc` folder
* **Assembly annotation** index files are included in the `/annotation` folder

# Release 2 Assemblies
 
 Assemblies created as part of HPRC processing are accessioned in GenBank and are available both from Genbank and the HPRC S3 bucket. Versions in the S3 bucket are all in the [PanSN format](https://github.com/pangenome/PanSN-spec). This includes references such as CHM13, GRCh38, and HG002. For this reason if you want to pull the exact assembly versions used for Release 2 analysis please use the assemblies from S3 (in the assembly index file) or the AGC archive.

 
## How To Download Assemblies

### Using the Index File
To download an individual assembly you can use the assembly index file (from this repository) to find the assembly URI and then to use the AWS CLI to download the individual assemblies. Each assembly can be downloaded without egress fees but users without AWS credentials need to include `--no-sign-request` as shown in the example below:
```
aws s3 --no-sign-request cp \
   s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00408/assemblies/freeze_2/HG00408_pat_hprc_r2_v1.0.1.fa.gz \
   ./
```

If you want to download all of the assembly files using the index file, you can loop through the index file to create the download commands:

```
## get a local copy of the assembly index file
wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.6.1.index.csv

## S3 locations for assembly are stored in column 13
ASSEMBLY_COLUMN_NUM=13

## pull assembly column then use AWS CLI to download files
tail -n +2 assemblies_pre_release_v0.6.1.index.csv | awk -F',' -v col="$ASSEMBLY_COLUMN_NUM" '{print $col}' | while read -r assembly_file; do
    echo "Downloading $assembly_file..."
    aws s3 --no-sign-request cp "$assembly_file" .
done
```
### From the AGC Archive

Assemblies are also available as a single 3.3GB file in the
[AGC](https://github.com/refresh-bio/agc) (Assembled Genomes Compressor) format. This archive includes the same assemblies and assembly versions as the assembly index file. Note that in order to extract sequences from the archive, users must have [AGC installed](https://github.com/refresh-bio/agc?tab=readme-ov-file#prebuild-releases).

You can download all HPRC assemblies and selectively extract entire assemblies or contigs/scaffolds as shown below.
```sh
# download AGC archive of Release 2 assemblies
wget https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/B4174A5F-F20E-4DCF-8470-F8A907B640BC--HPRCv2_0.6.1_pr_agc_submission/HPRC_r2_assemblies_0.6.1.agc

# list all samples
agc listset HPRC_r2_assemblies_0.6.1.agc

# extract assembly for haplotype 1 of HG00097
agc getset \
  HPRC_r2_assemblies_0.6.1.agc \
  HG00097_hap1_hprc_r2_v1.0.1 \
  > HG00097_hap1_hprc_r2_v1.0.1.fa

# extract a specific contig from HG00097 haplotype 1
# this contig corresponds to chromosome 1 (according to the chromAlias file)
agc getctg \
  HPRC_r2_assemblies_0.6.1.agc \
  HG00097#1#CM094060.1 \
  > HG00097_hap1_hprc_r2_v1.0.1_CM094060.1.fa
```

## Assembly Index File
The assembly locations along with some metadata are collected in an index file. Reference-level assemblies for CHM13v2, GRCh38, and HG002 (Q100) are included in the index file to help ensure that all HPRC analysis teams are using the same reference versions. The references pointed to in the assembly index have sequence IDs prepended with their sample_id and haplotype (0 for CHM13 and GRCh38) according to the [PanSN spec](https://github.com/pangenome/PanSN-spec). This is useful for pangenome applications where having multiple sequence IDs that are the same (for example chr1 from CHM13 and GRCh38) causes redundancy. Users who wish to analyze assemblies directly will want the original versions of the assemblies given below: 
|assembly|assembly (PanSN)|
|-|-|
|[HG002 Mat](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/HG002/assemblies/hg002v1.1.mat_MT.fasta.gz)|[HG002 Mat](https://s3-us-west-2.amazonaws.com/human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.mat_MT.PanSN.fa.gz)|
|[HG002 Pat](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/HG002/assemblies/hg002v1.1.pat.fasta.gz)|[HG002 Pat](https://s3-us-west-2.amazonaws.com/human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.pat.PanSN.fa.gz)|
|[GRCh38](https://s3-us-west-2.amazonaws.com/human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz)|[GRCh38](https://s3-us-west-2.amazonaws.com/human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz)|
|[CHM13](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0_maskedY_rCRS.fa.gz)|[CHM13](https://s3-us-west-2.amazonaws.com/human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz)|

The columns of the index file are as follows:
1. **sample_id**: Sample ID from Coriell (for example HG01884). For samples with GM/NA names, use the NA prefix.
2. **haplotype**: (0|1|2) Integer representation of haplotype
    * 1 for paternal, 2 for maternal with trio phasing. 0 for CHM13 and GRCh38 
    * For other phasing approaches haplotype 1 contains chrY in male samples. Haplotype 2 contains chrX and mitochondrial sequence.
3. **phasing**: (trio|hic) Phasing approach used to separate assembled sequences into distinct haplotypes, with or without parent-of-origin assignment.
4. **assembly_method**: (hifiasm|verkko) assembler used
5. **assembly_method_version**: version of assembler used
6. **assembly_date**: Best-guess date of assembly. 
7. **assembly_name**: Unique name of the assembly. Use for annotation and QC output naming.
8. **source**: where assembly was sourced from
    * hprc: Assembled as part of the HPRC's production efforts (sample can be from HPRC or HPRC PLUS)
    * hpp: Assembled outside the HPRC but shared with the HPRC as part of an international collaboration
    * extramural: Assembed in another project (for example the HG002 Q100 project for HG002, or the T2T consortium for CHM13)
9. **genbank_accession**: Genbank accession of assembly.
10. **assembly_md5**: S3 location of MD5 checksum.
11. **assembly_fai**: S3 location of fai file.
12. **assembly_gzi**: S3 location of gzi file.
13. **assembly**: S3 location of assembly. 

### Outstanding Samples
The following samples have assemblies forthcoming
* HG03492: waiting on Genbank updates
  * Sample was in Year 1 (Release 1) sample set

### Assembly Index Change Log

```
* v0.1 (2024 Oct 11): Added 156 samples to index
* v0.2 (2024 Nov 07): Added 40 more samples (bringing total number to 196)
* v0.3 (2024 Dec 20): Added 20 more samples (bringing the total number to 216)
  * prior assemblies were re-uploaded to correct fasta sort order (see issue below)
* v0.4 (2025 Jan 12): Added 11 samples (bringing the total number to 227)
  * 10 samples from AMED project
  * 1 sample from WashU Pedigree project
* v0.5 (2025 Jan 21): Added 4 samples (bringing the total number to 231)
  * 4 samples from Human Technopole
* v0.6 (2025 Feb 09): Added reference assemblies HG002, CHM13, GRCh38
  * Fixed haplotype swap in three samples (see issue below). 
* v0.6.1 (2025 Feb 15): use PanSN versions of reference assemblies
  * replaced HG002, GRCh38, and CHM13 assemblies with the same assemblies but with PanSN sequence naming. For example CHM13's chr1 is now named CHM13#0#chr1.
```

## Known Issues

- **Assemblies not in proper sort order** – ✅ Fixed in **v0.3**
  - The original fasta files did not have sequences in natural sort order. All prior assemblies were reuploaded as sorted fastas. To reflect the fact that there was a change, but it is not expected to alter any analysis outputs the assembly names (and filenames) were changed from v1 to v1.0.1.
- **Three samples were labeled with wrong haplotype** – ✅ Fixed in **v0.6**  
  - Three samples were haplotype swapped (in versions 1.0 and 1.0.1):
    - HG01978  
    - HG02257  
    - HG03516  
  - New corrected assemblies are assigned version v1.1.0  
  - To maintain records and intentionally break prior URIs included in assembly data tables, the old (incorrect) versions and their annotations have been moved to the haplotype_swapped folder of the relevant assembly folders.  

