# HPRC Release 2
## Repo Organization

## Data Tables

If you are looking for how to get the assemblies or information about the assemblies, navigate to the `data_tables` folder.

## Uploading Results
### How to upload Release 2 analysis outputs

* Reach out on the #Data channel of the HPRC Slack to request credentials for the HPRC bucket
* Organize your data by sample and name with the assembly name.
  * Organize the files by sample to allow for easier indexing
    * For example `upload_folder/{sample_id}/sniffles/`
  * The assembly name can be found in the assembly index and should be used as a "key" to ensure that users know which file was used to create the results.
    * For example, analysis done for assembly `HG00408_pat_hprc_r2_v1.0.1` should be named `HG00408_pat_hprc_r2_v1.0.1.yourtool.bed`
* [Follow the instructions](https://github.com/human-pangenomics/hpp_data_pipeline/blob/main/sequencing_data/submission_to_HPRC/upload_instructions/HPP_Data_Upload_Instructions.pdf) to upload data to the bucket

### Criteria for upload & indexing of results

Analysis results should be uploaded to the S3 bucket if they are reasonably expected to be useful across the consortium. 

## Notes
The following folders are used for tracking and aiding assembly and assembly QC production. 
* **assembly**: assembly notes and tracking
* **polishing**: polishing of raw assemblies
* **upload**: clean up and upload to Genbank (including contamination fixes)
* **download**: download and renaming of assemblies from Genbank
* **assembly_qc**: QC of genbank assemblies
* **hpc**: helper scripts for launching analysis
* **reference_data**: notes on reference data provenance


