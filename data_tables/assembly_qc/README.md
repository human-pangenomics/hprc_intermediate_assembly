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
