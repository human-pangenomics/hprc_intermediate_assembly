# Release 2 Sequencing Data

The release 2 sequencing data tables is synchronized to the latest samples in [assemblies_pre_release_version.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/assemblies_pre_release_v0.5.index.csv) from the most recent [HPRC_metadata/main/data/hprc-data-explorer-tables](https://github.com/human-pangenomics/HPRC_metadata/tree/main/data/hprc-data-explorer-tables).

**Google Spreadsheet**:[R2 Sequencing Data Index](https://docs.google.com/spreadsheets/d/1EuZNw2sdijKYpJLqgHUYBOF6F4ECry8EWKZzVPjAw4Y/edit?usp=sharing)

## How to download
Assembly sequencing data can be downloaded using the path column in the data_SequencingTechnology_pre_release.index.csv file.

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
* Combination of Revio and Sequel II instrument models.
* DeepConsensus rebase called Y1-Y3 Sequel II.
* MM_tag column indicates methylation information.

#### Primary Metadata Identifiers

- **sample_ID**: Unique identifier for the sample.
- **filetype**: Type of the file (e.g., FASTQ, BAM).
- **filename**: Name of the file associated with the sample.
- **path**: Filepath to the associated data file.

#### General Metadata

- **study**: Name or description of the study the data is associated with.
- **title**: Title of the sequencing project or dataset.
- **accession**: Accession number for the dataset or sample.
- **bioproject_accession**: BioProject ID linking the data to a broader study.
- **biosample_accession**: BioSample ID providing metadata on the sample.
- **design_description**: Description of the experimental design.
- **notes**: Additional notes or comments about the sample or dataset.

#### Sample Information

- **generator_contact**: Contact information of the data generator.
- **generator_facility**: Facility where the sequencing or data generation occurred.

#### Library Information

- **library_ID**: Unique identifier for the library preparation.
- **library_strategy**: Library preparation strategy (e.g., WGS, RNA-seq).
- **library_source**: Source material used for library preparation (e.g., genomic DNA, RNA).
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

- **ccs_algorithm**: Version or type of circular consensus sequencing (CCS) algorithm used.
- **DeepConsensus_version**: Version of the DeepConsensus software used for consensus generation.

#### File Information

- **filename**: Name of the file associated with the sample.
- **path**: Filepath to the associated data file.
- **deepconsensus_file**: Name of the DeepConsensus-generated file.
- **deepconsensus_path**: Filepath to the DeepConsensus file.

#### Production and Coverage

- **production**: Indicates if the dataset is part of a production pipeline.
- **coverage**: Sequencing coverage of the sample.
- **deepconsensus_coverage**: Coverage calculated after applying DeepConsensus.

#### Metrics and Statistics

- **total_reads**: Total number of reads in the dataset.
- **total_bp**: Total base pairs in the dataset.
- **total_Gbp**: Total gigabase pairs in the dataset.
- **mean**: Mean read length.
- **min**: Minimum read length.
- **max**: Maximum read length.
- **N25**: N25 value (length of the shortest read contributing to 25% of the total dataset).
- **N50**: N50 value (length of the shortest read contributing to 50% of the total dataset).
- **N75**: N75 value (length of the shortest read contributing to 75% of the total dataset).
- **quartile_25**: First quartile of read lengths.
- **quartile_50**: Median of read lengths.
- **quartile_75**: Third quartile of read lengths.
- **ntsm_score**: Score calculated using the NTSM method.
- **MM_tag**: Indicates methylation tagging or other molecular tags.

### HiC
[data_hic_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hic_pre_release.index.csv)

### Illumina 1K Genomes
[data_illumina_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv)
* **NHGRI AnVIL Dataset Catalog Consortia**: [1000G](https://anvilproject.org/data/consortia/1000G/workspaces) **Workspace (Terra)**: [1000G-high-coverage-2019](https://anvil.terra.bio/#workspaces/anvil-datastorage/1000G-high-coverage-2019)

## Sequence Index File Change Log
```
* v0.5 (2025 Jan 27): Add DeepConsensus metadata to HiFi data table.
* v0.5 (2025 Jan 22): Add assembly phasing metadata to Illumina data table.
```

