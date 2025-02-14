# Release 2 Sequencing Data

The release 2 sequencing data tables is synchronized to the latest samples in [assemblies_pre_release_version.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/assemblies_pre_release_v0.5.index.csv) from the most recent [HPRC_metadata/main/data/hprc-data-explorer-tables](https://github.com/human-pangenomics/HPRC_metadata/tree/main/data/hprc-data-explorer-tables).

**Google Spreadsheet**:[R2 Sequencing Data Index](https://docs.google.com/spreadsheets/d/1EuZNw2sdijKYpJLqgHUYBOF6F4ECry8EWKZzVPjAw4Y/edit?usp=sharing)

## How to download
Assembly sequencing data can be downloaded using the path column in the data_SequencingTechnology_pre_release.index.csv file (e.g., data_ont_pre_release.index.csv).

### Example:
Individual sequence files can be downloaded via the AWS CLI using the following command:

```
aws s3 --no-sign-request cp \
   s3://human-pangenomics/working/HPRC/HG00558/raw_data/nanopore/guppy_6/02_08_22_R941_HG00558_1_Guppy_6.5.7_450bps_modbases_5mc_cg_sup_prom_pass.bam \
   ./
```

### Downloading All Files Using the Sequencing Technology Index Files:

If you want to download all the assembly sequencing data files listed in the technology index files, you can use the [data_pull_example.sh](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_pull_example.sh)


## Sequence Index File
The R2 technology sequence index tables provide data processing summaries per file produced by the [hpp_production WDL workflows](https://github.com/human-pangenomics/hpp_production_workflows/tree/master/data_processing/wdl/workflows). Following, the sequence files are released to the sample's working path directory [s3://human-pangenomics/working/HPRC/](https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=working/).

### Oxford Nanopore Technologies

[data_ont_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_ont_pre_release.index.csv)
* In BAM format and basecalled to include methylation information. 
* Metadata data processing summary:
   * 100kb+ with a target of 30x coverage per sample.
   * R9/R10 sequencing_chemistry kits.

### PacBio HiFi
[data_hifi_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv)

[data_deepconsensus_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv)

#### User Notes
* 219 PacBio HiFi samples present.
* Combination of Revio and Sequel II instrument models.

* 163 samples have DeepConsensus fastq sequence files available.

* DeepConsensus rebase called Y1-Y3 Sequel II.
* 13 samples have only DeepConsensus. 
```Python
['NA18906', 'NA21309', 'NA20762', 'HG005', 'NA20827', 'NA20503', 'NA19240', 'HG03486', 'HG03098', 'NA20806', 'HG01109', 'NA20129', 'HG02818']
```

* 9 samples have Revio and Sequel II rebase called with DeepConsensus. Therefore, the samples will be in the DeepConsensus and HiFi index data tables.
```
['HG04187', 'HG06807', 'HG02080', 'HG03492', 'HG01243', 'HG02055', 'HG02723', 'HG02109', 'HG02145']
```

* 150 samples have HiFi and DeepConsensus sequence files. In the HiFi index data table, 141 samples have DeepConsensus sequence files that match the sample Sequel II platform unit identifier.
  
* 22 samples have no MM modification tags.
```Python
["HG00438", "HG00735", "HG01106", "HG02622", "HG02630", "HG02717", "HG02886", "HG03453", "HG03471", "HG03540", "HG03579", "HG00733", "NA18940", "NA18943", "NA18944", "NA18945", "NA18948", "NA18959", "NA18960", "NA18967", "NA18970", "NA18982"]
```


#### Primary Metadata Identifiers

- **sample_ID**: Coriell sample identifier.
- **filetype**: The file type (e.g., FASTQ, BAM).
- **filename**: Name of the sequence file associated with the sample.
- **path**: AWS S3 path to the sequence data file.

#### General Metadata

- **study**: Name or description of the study the sequence data is associated with.
- **title**: Title of the sequencing project or dataset.
- **accession**: Accession number for the dataset or sample.
- **bioproject_accession**: BioProject identifier.
- **biosample_accession**: BioSample identifier
- **design_description**: Description of the experimental design.
- **notes**: Additional notes or comments about the sample or dataset.

#### Sample Information

- **generator_contact**: Contact information of the data generator.
- **generator_facility**: Facility where the sequencing or data generation occurred.

#### Library Information

- **library_ID**: Unique identifier for the library preparation.
- **library_strategy**: Library preparation strategy (e.g., WGS, RNA-seq).
- **library_source**: Source material for library preparation (e.g., genomic DNA, RNA).
- **library_selection**: Method used for library selection (e.g., size-selection, random priming).
- **library_layout**: Layout of the library (e.g., single-end, paired-end).
- **shear_method**: Method used to fragment the DNA or RNA.
- **size_selection**: Information about the size selection process.

#### Instrument and Sequencing Details

- **platform**: Sequencing platform used (e.g., PacBio, Illumina).
- **instrument_model**: Specific instrument model used for sequencing.
- **seq_plate_chemistry_version**: Chemistry version of the sequencing plate.
- **polymerase_version**: Version of the polymerase enzyme used.

#### Algorithm and Software Versions

- **ccs_algorithm**: Version of the circular consensus sequencing (CCS) algorithm used.
- **DeepConsensus_version**: Version of the DeepConsensus software used for consensus generation.y
- **deepconsensus_file**: Name of the DeepConsensus-generated file.
- **deepconsensus_path**:  AWS S3 path to the DeepConsensus sequence file.

#### Production and Coverage

- **production**: Indicates the sequence production center where the sequence file was generated.
- **coverage**: Sequencing coverage of the sample.
- **deepconsensus_coverage**: Coverage calculated after applying DeepConsensus.

#### Metrics and Statistics

- **total_reads**: Total number of reads in the sequence file.
- **total_bp**: Total base pairs in the sequence file.
- **total_Gbp**: Total gigabase pairs in the sequence file.
- **mean**: Mean read length.
- **min**: Minimum read length.
- **max**: Maximum read length.
- **N25**: N25 value (length of the shortest read contributing to 25% of the total sequence file).
- **N50**: The contiguity of sequencing reads is determined by the read length at which 50% of the total bases are contained in reads of that length or longer.
- **N75**: The contiguity of sequencing reads is determined by the read length at which 75% of the total bases are contained in reads of that length or longer.
- **quartile_25**: First quartile of read lengths, indicating the read length below which 25% of the reads fall.
- **quartile_50**: Median of read lengths, representing the middle value where 50% of the reads are shorter, and 50% are longer.
- **quartile_75**: Third quartile of read lengths, indicating the read length below which 75% of the reads fall.
- **ntsm_score**: Score calculated using the NTSM method.
- **MM_tag**: Methylation tag (TRUE or FALSE)

### HiC
[data_hic_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hic_pre_release.index.csv)

### Illumina 1K Genomes
[data_illumina_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv)
* **NHGRI AnVIL Dataset Catalog Consortia**: [1000G](https://anvilproject.org/data/consortia/1000G/workspaces) **Workspace (Terra)**: [1000G-high-coverage-2019](https://anvil.terra.bio/#workspaces/anvil-datastorage/1000G-high-coverage-2019)

### Kinnex (PacBio Iso-Seq full-length RNA sequencing)
[data_kinnex_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_kinnex_pre_release.index.csv)
Kinnex data is provided as flnc.bams.  See [PacBio IsoSeq documentation](https://isoseq.how/) for details. 


#### User Notes
* 202 R2 samples have Kinnex data available.
* IsoSeq was run per sample for a majority of the data resulting in a single flnc.bam per sample.  A subset of samples were run per smrtcell, resulting in multiple flnc.bams per sample, these data should be concatenated.  Read totals are reported per file.
* The following R2 samples have Kinnex data generated, but are in progress.
```
['HG01123','HG02486','HG02559','HG03471']
```
* The following R2 samples do not have Kinnex data generated.  They are reference, HPRC-PLUS, and HPP samples.
```
['CHM13','GRCh38','HG002','HG005','HG00733','HG01109','HG01243','HG02055','HG02080','HG02109','HG02145','HG02723','HG02818','HG03098','HG03486','HG06807','NA18906','NA18940','NA18943','NA18944','NA18945','NA18948','NA18959','NA18960','NA18982','NA19240','NA20129','NA21309']
```



## Sequence Index File Change Log
```
* v0.5 (2025 Feb 12): Add Kinnex data table and documentation. 
* v0.5 (2025 Jan 27): Add DeepConsensus metadata to HiFi data table.
* v0.5 (2025 Jan 22): Add assembly phasing metadata to Illumina data table.
```

