# Sample Documentation
This document provides information about samples which had noteworthy events in processing for Release 2. In particular there is an attempt to document:
* Why certain samples with sufficient sequencing data are missing from Release 2
* Samples which are included in the release, but had either unexpected genomic features (which were either left alone or manually fixed) that may affect downstream processing

## Summary Table

| Sample ID | Release 2 Status | Event | Notes |
|-----------|--------|--------|--------|
| NA18612 | Omitted | QC failure | Join found between chr16 and chr17 |
| HG02683 | Omitted | QC failure | Missing genes; cell line has RAD51 mutation |
| HG03458 | Omitted | QC failure | Missing genes + section of p-arm of chr15; sample had low Hi-C coverage at time of assembly |
| HG04153 | Omitted | Processing failure | Sample and data are likely fine |
| HG00867 | Omitted | Processing failure | Sample and data are likely fine |
| NA19131 | Omitted | Processing failure | Sample and data are likely fine |
| HG03492 | Omitted | Processing failure | Sample and data are likely fine |
| HG02738 | Included | QC failure | Potential EBV integration (manually removed from assembly) |
| NA19159 | Included | QC failure | Potential EBV integration (manually removed from assembly) |
| HG00272 | Included | Anomaly noted during analysis | chrX inversion, held out of pangenome |
| HG02145 | Included | Anomaly noted during analysis | Y chromosome sequencing coverage is lower than rest of genome | 

## Potential Cell-line Artifacts

### Omitted Samples

#### NA18612
- Release 2 candidate assemblies were found to have joins between chr16 and chr17.
    -  Hap1 has a balanced translocation which is also seen when this sample is assembled with Verkko
    -  Hap2 has an unbalalanced translocation which is not seen when this sample is assembled with Verkko
- Sequencing reads appear to support the translocation in haplotype 1 (but not haplotype 2)
- The assemblies had unremarkable (as in normal) base quality, contiguity, and gene statistics.
- The [assembly](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA18612/assemblies/freeze_2/) was had the join in hap2 broken and the join in hap1 was retained. Depsite this, it was held out of Release 2 as is was unclear if the translocation is a cell line artifact (and therefore whether or not it represents real human variation).
- For additional information [see this presentation](https://docs.google.com/presentation/d/1AzZ6ME_QtVGC_3KdC6dicCTgqRuuCpvMY5DWlcm7Gbo/edit?usp=sharing)

#### HG02683
- Release 2 candidate assembly was found to have missing genes (as measured by Compleasm and asmgene)
- RAD51 mutation in cell line may affect results
- Some literature shows that this sample has a high number of denovo variants
- Verkko assembly with trio phasing was found to replicate problems in Hifiasm trio assembly but Hi-C phasing with Verkko produced better gene statistics. 
- The [assembly](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02683/assemblies/freeze_2/assembly_pipeline/ncbi_upload/) was held out of release 2 since it was not clear if a sample with denovo variants (which could be cell line artifacts) should be included in a panel of reference genomes.
- For additional information [see this presentation](https://docs.google.com/presentation/d/1sk7_nwMlQLHUAClfcdM0h-CEVuj_Nx_EUWcJzGCKRF0/edit?usp=sharing)

#### HG03458
- Haplotype 2 is missing genes as measured by asmgene and Compleasm.
- Alignment of the assembly to CHM13 shows that around 50Mbp of sequence in the p-arm of chr15 is missing.
- At the time of assembly (and freeze of data for release) only around 15X Hi-C was available for phasing. More Hi-C data is now available which may improve results.
- This sample was held out of Release 2 since the missing sequence is likely an assembly artifact and would complicate downstream analysis.
- For additional information [see this presentation](https://docs.google.com/presentation/d/1sk7_nwMlQLHUAClfcdM0h-CEVuj_Nx_EUWcJzGCKRF0/edit?usp=sharing)

### Samples Included In Release

#### HG02738
- EBV sequence was found at the end of one sequence in the Release 2 candidate assembly (in the q-arm of chr14)
- The Verkko assembly for this sample had similar EBV sequence integration (also in the q-arm of chr14)
- Looking at the assembly and the reads that support it, it may be the case that EBV is integrated in the genome (and it may be at an integration hotspot near the IGH locus)
- The integrated EBV sequence was removed from the assembly as it was unclear if it is merely an artifact of the cell line creation process.
    - The assembly that was uploaded to Genbank can be found [here](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02738/assemblies/freeze_2/assembly_pipeline/ncbi_upload/) alongside the "raw" version with EBV integrated at the end of the contig.
- For additional information [see notes from EBV removal](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/7ad3208e9a4d7b3a0bd4c2aebf800df69de74426/upload/batch2/batch2_genbank_fix.sh)

#### NA19159
- EBV sequence was found at the end of one sequence in the Release 2 candidate assembly
- The Verkko assembly for this sample did have EBV sequence that was identified
- The integrated EBV sequence was removed from the assembly as it was unclear if it is merely an artifact of the cell line creation process.
    - The assembly that was uploaded to Genbank can be found [here](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19159/assemblies/freeze_2/assembly_pipeline/ncbi_upload/) alongside the "raw" version with EBV integrated at the end of the contig.
- For additional information [see notes from EBV removal](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/af3927019faa2a7d5b56d36dd23b6b3f0dded261/upload/batch7/batch7_genbank_fix.sh)

#### HG00272
- Large inversion in chrX
    - Found in HG00272#2#JBIRDO010000040.1
    - Some sort of inversion seems to be supported by the data
- Included in release but held out of pangenome because it creates large, nasty structures and because it is unclear if the assembly is correct here.
- For additional information [see this presentation](https://docs.google.com/presentation/d/16q3jsxDxb4NJEzQy7gIR3O3JkXWVpyjFMPppsml0laE/edit?usp=sharing)


#### HG02145
- It was noted that this sample's Y chromosome sequencing coverage is lower (around 10X) than rest of genome (around 35X) and this likely stems from the loss of chrY in some cells. This sample is currently included in the release as chrY assemblies often fragmented.


## Processing Issues

* **HG04153**: Failed polishing workflow
* **HG00867**: Failed polishing worflow
* **NA19131**: Failed mitohifi workflow
* **HG03492**: Waiting on Genbank to rerelease