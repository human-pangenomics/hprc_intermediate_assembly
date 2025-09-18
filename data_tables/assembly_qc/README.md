## Assembly QC

### Flagger: 
[HMM Flagger](https://github.com/mobinasri/flagger) run starting w/ Minimap2 and resulting in predictions for both ONT and HiFi as bed files. The bed files linked below are for the "conservative" predictions and do not include entries for regions predicted to be haploid. 
* HiFi Predictions: bed file with regions predicted to be problematic
* HIFi Mappable Regions: bed file with regions with > MAPQ10
* ONT Predictions: bed file with regions predicted to be problematic
* ONT Mappable Regions: bed file with regions with > MAPQ10

In addition to the main outputs indexed in the above files, there is an index file (of sorts) with many other Flagger outputs:
* HiFi/ONT Processing Metadata
  * BAM & BAI files
  * rmsk files for genome browsers
  * cov_gz
  * stats_tsv
  * conservative_stats_tsv
  * bigwig
  * high_mapq_bigwig
  * high_clip_bigwig


### NucFlag: 
[NucFlag](https://github.com/logsdon-lab/NucFlag) takes sample-matched HiFi reads that are aligned to an assembly and identifies potential assembly errors based on the presence of secondary bases in the alignment (when there should be none). It also detects missasemblies based on coverage information and finding spurious looking variants. Note that NucFlag was initially designed and tested for use in centromeres, but should in principal work in other regions of the genome if mapping to those regions can be trusted and the coverage is over 20X. HiFi bams from Flagger were used as inputs. For more information about how NucFlag was run for the HPRC see [here](https://github.com/koisland/Snakemake-NucFlag-HPRC/blob/main/README.md).

* nucflag: bed file with regions predicted to be problematic
* nucflag_first_coverage: bigwig file of coverage of most common base in aligned HiFi reads
* nucflag_second_coverage: bigwig file of coverage of second most common base in aligned HiFi reads

In addition to the outputs above, tars of images generated of problematic regions are included in S3.

## Annotation Indexes Change Log

```
NucFlag:
* v0.2 (2025 Sep 18): added 6 assemblies (3 samples) that were missing
    * v0.1 index file was missing annotations for the samples that had haplotype swaps (which have since been fixed). NucFlag results for these sample's assemblies have now been added.
      - HG01978  
      - HG02257  
      - HG03516 
    All files that were in the 0.1 index file were unchanged.

```