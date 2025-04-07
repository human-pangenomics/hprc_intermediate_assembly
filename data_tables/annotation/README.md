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
