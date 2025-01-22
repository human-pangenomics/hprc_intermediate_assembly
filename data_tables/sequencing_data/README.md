# Release 2 Sequencing Data

The release 2 sequencing data tables is synchronized to the latest samples in [assemblies_pre_release_version.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/assemblies_pre_release_v0.5.index.csv) from the most recent [HPRC_metadata/main/data/hprc-data-explorer-tables](https://github.com/human-pangenomics/HPRC_metadata/tree/main/data/hprc-data-explorer-tables).

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

If you want to download all the assembly sequencing data files listed in the technology index files, you can use the following script:

```bash
$ data_pull_example.sh

```

## Sequence Index File
The R2 technology sequence index tables provide data processing summaries per file produced by the [hpp_production WDL workflows](https://github.com/human-pangenomics/hpp_production_workflows/tree/master/data_processing/wdl/workflows). Following, the sequence files are released to the sample's working path directory (s3://human-pangenomics/working/HPRC/)[https://s3-us-west-2.amazonaws.com/human-pangenomics/index.html?prefix=working/].

### Oxford Nanopore Technologies

[data_ont_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_ont_pre_release.index.csv)

### PacBio HiFi
[data_hifi_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv)

[data_deepconsensus_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv)

### HiC
[data_hic_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hic_pre_release.index.csv)

### Illumina 1K Genomes
[data_illumina_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv)
* NHGRI AnVIL Dataset Catalog Consortia: 1000G Workspace (Terra): [1000G-high-coverage-2019](https://anvil.terra.bio/#workspaces/anvil-datastorage/1000G-high-coverage-2019)

## Sequence Index File Change Log
```
* v0.5 (2025 Jan 22): Add assembly phasing metadata to Illumina table.
```

