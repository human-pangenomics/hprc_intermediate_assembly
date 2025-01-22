# Release 2 Sequencing Data

The release 2 sequencing data tables is synchronized from the latest samples[assemblies_pre_release_version.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/assemblies_pre_release_v0.5.index.csv) to the most recent [HPRC_metadata/main/data/hprc-data-explorer-tables](https://github.com/human-pangenomics/HPRC_metadata/tree/main/data/hprc-data-explorer-tables).

## How to download
Assembly sequencing data can be downloaded using the path column in the data_SequencingTechnology_pre_release.index.csv file.

### Example:
Individual sequence files can be downloaded via the AWS CLI using the following command:

```
aws s3 --no-sign-request cp \
   s3://human-pangenomics/working/HPRC/HG00558/raw_data/nanopore/guppy_6/02_08_22_R941_HG00558_1_Guppy_6.5.7_450bps_modbases_5mc_cg_sup_prom_pass.bam \
   ./
```

### Downloading All Files Using the Index File:

If you want to download all the assembly files listed in the index file, you can use the following script:

```bash
# Get the sequence summary files
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_hic_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_ont_pre_release.index.csv


```

## Sequence Index File


[data_deepconsensus_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv)

[data_hic_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hic_pre_release.index.csv)

[data_hifi_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv)

[data_illumina_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv)

[data_ont_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_ont_pre_release.index.csv)
