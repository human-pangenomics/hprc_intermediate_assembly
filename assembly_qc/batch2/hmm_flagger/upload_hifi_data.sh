#!/bin/bash
#SBATCH --job-name=wget_masri
#SBATCH --partition=long
#SBATCH --mail-user=masri@ucsc.edu
#SBATCH --nodes=1
#SBATCH --mail-type=FAIL,END
#SBATCH --mem=2gb
#SBATCH --cpus-per-task=2
#SBATCH --output=%x.%j.log
#SBATCH --time=100:00:00


cd /private/groups/hprc/qc_hmm_flagger/hprc_intermediate_assembly/assembly_qc/batch2/hmm_flagger/hifi/s3_upload

ssds staging upload \
    --submission-id ca366a13-5bad-487b-8a57-97344e9aa0e4 \
    upload \
    &>>hmm_flagger_hifi_s3_upload.stderr