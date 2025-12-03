# Release 2 Assembly Annotation Files
## Repeats

### RepeatMasker: 
Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/workflows/repeat_masker.wdl)
> **INDEX FILES:**
> * **RepeatMaskser (OUT)**: `repeat_masker/repeat_masker_out_hprc_r2_v1.0.index.csv`
> * **RepeatMasker (BED)**: `repeat_masker/repeat_masker_bed_hprc_r2_v1.0.index.csv`
>   * Converted from out file using RM2BED.py
* Other files on S3 but not indexed:
  * Masked fastas
  * RMSK files for genome browsers

```
(PARTIAL) CHANGE LOG:
* v3 (2025 Sep 11): added 80 assemblies which were missing; corrected assembly names.
    * v2 had 80 assemblies from R2 that were missing (though they were on S3). These were added to complete the index.
    * Assembly names for some samples included assembly version of the form v1 instead of the more correct v1.0.1. Both names work, but the full version makes lookups and joins easier.
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file (and iterated version number) to reflect release structure

```
### CenSat
CenSat annotations from [CAW (Centromere Annotation Workflow)](https://github.com/kmiga/alphaAnnotation/tree/main)
> **INDEX FILES:**
> * **CenSat (BED)**: `censat/censat_hprc_r2_v1.0.index.csv`
>   * Centromere BED file of centromeric satellite (ASat, HSat, etc) annotations
> * **CenSat centromere (BED)**: `censat/censat_centromeres_hprc_r2_v1.0.index.csv` 
>   * Centromere regions bed
* Other files on S3 but not indexed:
  * HOR BED (Higher-Order Repeats of alpha satellites)
  * HOR SF BED (superfamily annotations of alpha satellites monomers)
  * Strand BED (strand information bed for centromeric satellites)

```
(PARTIAL) CHANGE LOG:
* v3.1 (2025 Sep 11): corrected assembly names.
    * Assembly names for some samples included assembly version of the form v1 instead of the more correct v1.0.1. Both names work, but the full version makes lookups and joins easier.
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file (and iterated version number) to reflect release structure
```    
### SegDups
Segmental Duplications were produced by [SEDEF](https://github.com/vpc-ccg/sedef). Repeats in the assemblies were identified using TRF, RepeatMasker, and Windowmasker. The identified repeats were merged and used to softmask the assemblies and the soft masked assemblies were used as input to SEDEF. The output from SEDEF was filtered for pairwise sequence identity >90%, length > 1 kbp, and satellite content <70%.

> **INDEX FILES:**
> * **SegDups (BED)**: `segdups/segdups_hprc_r2_v1.1.index.csv`

```
CHANGE LOG:
* v1.0 (2025 Jun 27): initial commit
* v1.1 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
```  
## Genes
### Comparative Annotation Toolkit (CAT)
The [CAT](https://github.com/ph09/CAT2) generates consensus gene annotations for a set of assemblies from annotations on a reference assembly, Cactus alignments of the assemblies, including liftoff and miniprot based annotations, as well as RNA-seq and IsoSeq data. Release 2 gene annotations were created with the v2 pangenomes as well as kinnex data generated as part of Release 2.

> **INDEX FILES:**
> * **CAT genes (GFF3)**: `cat/cat_genes_hprc_r2_v1.2.index.csv`


**Note:** If you are looking for gene annotations for the included references, we have included exemplar annotations below. Note that these annotations are not in the PanSN spec.
* GRCh38 annotations from [Gencode](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.annotation.gff3.gz)
* CHM13 Liftoff-based annotations from the Salzberg Lab in the [T2T area of the HPRC bucket](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_RefSeq_Liftoff_v5.2.gff3.gz)
* HG002 Liftoff-based annotations from the Salzberg Lab ([maternal](ftp://ftp.ccb.jhu.edu/pub/data/hg002-q100/v0.5/hg002.v1.1.loff.v0.5.mat.gff.gz) / [paternal](ftp://ftp.ccb.jhu.edu/pub/data/hg002-q100/v0.5/hg002.v1.1.loff.v0.5.pat.gff.gz))

```
CHANGE LOG:
* v1.0 (2025 Jun 24): initial commit
* v1.1 (2025 Sep 04): point to updated v1.1 gff3 files for all assemblies.
    * v1.1 files have spurious copies for genes with VNTRs removed and minor fixes to paralog assignment and CDS frame assignment 
* v1.2 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
```  

### Liftoff
Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/liftoff.wdl) using CHM13 annotations derived from [JHU RefSeqv110 + Liftoff v5.2](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_RefSeq_Liftoff_v5.2.gff3.gz). Note that the input gff3 was manually fixed ([available here](https://public.gi.ucsc.edu/~pnhebbar/chm13v2.0_RefSeq_Liftoff_v5.1.gff3)) with the introduction unique postfixes that fix duplicate IDs which were present.

> **INDEX FILES:**
> * **liftoff genes (GFF3)**: `liftoff/liftoff_genes_hprc_r2_v1.0.index.csv`

```
(PARTIAL) CHANGE LOG:
* v0.3 (2025 Feb 25): Added annotation for 36 additional assemblies
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
```  
## Chromosomes
### Chromosome Information
Chromosome assignments for all sequences. Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/assign_chromosomes.wdl).

> **INDEX FILES:**
> * **chromAlias (TXT)**: `chrom_assignment/chrom_alias_hprc_r2_v1.0.index.csv`
>   * Text files with alternate names for each assembly 
>   * Useful for looking up chromosome assignments or converting between sequence IDs
> * **T2T Chromosomes (TSV)**: `chrom_assignment/t2t_sequences_hprc_r2_v1.0.index.csv`
>   * Text files with list of T2T chromosomes for each assembly
> * **Gaps (BED)**: `chrom_assignment/gaps_hprc_r2_v1.0.index.csv`
>   * Bed files with gaps found in each assembly

#### Finding a sequence's chromosome assignment

Parsing the chromAlias files can help you find an assembly's representation of a given chromosome. Chromsome Alias assignments are broken into:
* Full T2T representations (one contig/scaffold which represents the entire chromosome)
* Assignment to one chromosome, but not T2T
* Not assigned (which usually means that a sequence maps to an acrocentric p-arm)

Below is an example of each (in order)

```
# assembly  ucsc  genbank
HG00097#1#CM094060.1  chr1  CM094060.1
HG00097#1#JBIRDD010000002.1 chr13_JBIRDD010000002.1_random  JBIRDD010000002.1
HG00097#1#JBIRDD010000019.1 chrUn_JBIRDD010000019.1 JBIRDD010000019.1
```

```
CHANGE LOG:
* v0.1 (2025 Feb 21): initial commit
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
```  
## Alignments

### Alignments to Reference Genomes
Winnowmap2 Winnowmap (v2.03) alignments (BAM) of the R2 assemblies against CHM13 and GRCh38. For more information see these [notes on Github](https://github.com/wwliao/hprc_release2_variant_calling/tree/main)

> **INDEX FILES:**
> * **Assembly aligned to CHM13 (BAM)**: `alignments_to_ref/alignments_to_ref_chm13_winnowmap_hprc_r2_v1.1.index.csv`
> * **Assembly aligned to CHM13 (BAM.BAI)**: `alignments_to_ref/alignments_to_ref_chm13_winnowmap_bai_hprc_r2_v1.1.index.csv`
> * **Assembly aligned to GRCh38 (BAM)**: `alignments_to_ref/alignments_to_ref_grch38_winnowmap_hprc_r2_v1.1.index.csv`
> * **Assembly aligned to GRCh38 (BAM.BAI)**: `alignments_to_ref/alignments_to_ref_grch38_winnowmap_bai_hprc_r2_v1.1.index.csv`

Note that both CHM13 and GRCh38 have multiple versions. The files used as references in this analysis used masked PARs in chrY and included rCRS for the mito as well as an EBV sequence. See [here](https://github.com/wwliao/hprc_release2_variant_calling/tree/main?tab=readme-ov-file#reference-genomes) for more information. 

All assembly-to-reference BAM files in these indexes also have associate BAI files in the S3 bucket. To obtain an index file of the bai files you can convert the existing indexes with a sed command such as `sed 's/$/.bai/' input.csv > output.csv` 

```
CHANGE LOG:
* v1.0 (2025 Jun 24): initial commit
* v1.1 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
    * added index file for bam indexes
```  
### Chain Files
Chain files to CHM13 and GRCh38 were created from the HPRC's v2 pangenomes using `cactus-hal2chains`. 

> **INDEX FILES:**
> * **Minigraph-Cactus Chains to CHM13 (CHAIN)**: `chains/chains_to_chm13_mc_hprc_r2_v1.0.index.csv`
> * **Minigraph-Cactus Chains to GRCh38 (CHAIN)**: `chains/chains_to_grch38_mc_hprc_r2_v1.0.index.csv`

For browsers, bigChain.bb and bigChain.link.bb files can be found in the S3 bucket next to the chains. These files are not included in an index, but if want to create an index file of the bigbeds you can convert the S3 URIs included in the chain index with a sed command such as `sed 's/\.chain\.gz$/.bigChain.bb/' input.csv > output.csv` and `sed 's/\.chain\.gz$/.bigChain.link.bb/' input.csv > output.csv`.

```
CHANGE LOG:
* v0.1 (2025 Jun 12): initial commit
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
``` 
## Other
### Methylation
Methylation (5mC) predictions for assemblies in bigwig format are extracted with [modkit](https://github.com/nanoporetech/modkit) from ONT data aligned to the assemblies (which was created during Flagger processing). The WDL used can be found [here](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/modkit_pileup.wdl) 

> **INDEX FILES:**
> * **ONT-Based Methylation (BIGWIG)**: `methylation/ont_methylation_hprc_r2_v1.0.index.csv`

Bed files with detailed methylation information from modkit can be found next to bigwigs in the S3 bucket. The beds are not included in an index, but if you want to inspect the methylation predictions you can convert the S3 URIs included in the bigwig index with a sed command such as `sed 's/\.5mC\.bigwig/.CpG_pileup.bed/g' input.csv > output.csv`.

```
CHANGE LOG:
* v0.1 (2025 May 09): initial commit
* v1.0 (2025 Oct 03): pointed files to release (working area of bucket)
    * files are unchanged from prior version
    * renamed file to reflect release structure
``` 