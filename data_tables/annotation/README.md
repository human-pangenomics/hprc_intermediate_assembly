## Annotations

### RepeatMasker: 
Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/workflows/repeat_masker.wdl)
* Repeat Maskser OUT: out file
* Repeat Masker BED: bed file converted from out file using RM2BED.py
* Other files on S3 but not indexed:
  * Masked fastas
  * rmsk files for genome browsers
### CenSat
CenSat annotations from [CAW (Centromere Annotation Workflow)](https://github.com/kmiga/alphaAnnotation/tree/main)
* CenSat: bed file of centromeric satellites (ASat, HSat, etc)
* CenSat Centromeres: bed file of centromere regions
* Other files on S3 but not indexed:
  * HOR BED
  * HOR SF BED
  * Strand BED
### Liftoff
Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/liftoff.wdl) using CHM13 annotations derived from [JHU RefSeqv110 + Liftoff v5.2](https://s3-us-west-2.amazonaws.com/human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_RefSeq_Liftoff_v5.2.gff3.gz). Note that the input gff3 was manually fixed ([available here](https://public.gi.ucsc.edu/~pnhebbar/chm13v2.0_RefSeq_Liftoff_v5.1.gff3)) with the introduction unique postfixes that fix duplicate IDs which were present.

* Output GFF3


### Chromosome Information
Chromosome assignments for all sequences. Run from [HPRC's production workflows](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/assign_chromosomes.wdl).

* chromAlias: text file with chromosome assignments
* t2t_chromosomes: text file list of T2T chromosomes
* gaps: bed file with gaps found in the assembly

#### Finding a sequence's chromosome assignment

Chromsome Alias assignments are broken into:
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

### Methylation
Methylation (5mC) predictions for assemblies in bigwig format are extracted with [modkit](https://github.com/nanoporetech/modkit) from ONT data aligned to the assemblies (which was created during Flagger processing). The WDL used can be found [here](https://github.com/human-pangenomics/hpp_production_workflows/blob/master/annotation/wdl/tasks/modkit_pileup.wdl) 

* ont_methylation: bigwig track with 5mC from ONT

Bed files with detailed methylation information from modkit can be found next to bigwigs in the S3 bucket. The beds are not included in an index, but if you want to inspect the methylation predictions you can convert the S3 URIs included in the bigwig index with a sed command such as `sed 's/\.5mC\.bigwig/.CpG_pileup.bed/g' input.csv > output.csv`.

### Chain Files
Chain files to CHM13 and GRCh38 were created from the HPRC's v2 pangenomes using `cactus-hal2chains`. 


* mc_chains_to_chm13: Minigraph-CACTUS based chains of assemblies to CHM13 (gzipped)
* mc_chains_to_grch38: Minigraph-CACTUS based chains of assemblies to GRCh38 (gzipped)

For browsers, bigChain.bb and bigChain.link.bb files can be found in the S3 bucket next to the chains. These files are not included in an index, but if want to create an index file of the bigbeds you can convert the S3 URIs included in the chain index with a sed command such as `sed 's/\.chain\.gz$/.bigChain.bb/' input.csv > output.csv` and `sed 's/\.chain\.gz$/.bigChain.link.bb/' input.csv > output.csv`.