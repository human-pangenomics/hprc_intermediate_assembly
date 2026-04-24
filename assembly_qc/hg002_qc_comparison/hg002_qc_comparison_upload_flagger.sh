


###############################################################################
##                                   Prep                                    ##
###############################################################################

cd /private/groups/hprc/qc_testing/hg002_qc_comparison/

mkdir -p flagger/hifi/s3_upload
cd flagger/hifi/s3_upload


link_hmm_flagger_outputs() {
  local json="$1"
  local outdir="$2"

  mkdir -p "$outdir"

  local keys=(
    coverageGz
    biasTableTsv
    finalPredictionBed
    intermediatePredictionBed
    loglikelihoodTsv
    miscFlaggerFilesTarGz
    fullStatsTsv
    projectionSexBed
    projectionSDBed
    projectionAnnotationsBedArray
    bigwigArray
    readAlignmentBam
    readAlignmentBai
  )

  for key in "${keys[@]}"; do
    jq -r --arg key "$key" '
      to_entries[]
      | select(.key | endswith($key))
      | .value
      | if type == "array" then .[] else . end
      | select(. != null)
    ' "$json" | while read -r file; do
      
      # skip if file doesn't exist (optional safety)
      if [[ -e "$file" ]]; then
        ln -sf "$file" "$outdir/$(basename "$file")"
      else
        echo "WARNING: missing file for $key -> $file" >&2
      fi

    done
  done
}

###############################################################################
##                                Flagger HiFi                               ##
###############################################################################

JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.hifi/HG002.hprc_v2.for_genbank.hifi_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_hifi/
mkdir -p "$OUTDIR"

link_hmm_flagger_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>hg002_flagger_hifi_upload.stderr


###############################################################################
##                                Flagger ONT R9                             ##
###############################################################################

cd /private/groups/hprc/qc_testing/hg002_qc_comparison/flagger

mkdir -p ont_r9/s3_upload
cd ont_r9/s3_upload

JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.ont_r9/HG002.hprc_v2.for_genbank.ont_r9_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_ont_r9/
mkdir -p "$OUTDIR"

link_hmm_flagger_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>hg002_flagger_upload.stderr


###############################################################################
##                                Flagger ONT R10                            ##
###############################################################################

cd /private/groups/hprc/qc_testing/hg002_qc_comparison/flagger

mkdir -p ont_r10/s3_upload
cd ont_r10/s3_upload

JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.ont_r10/HG002.hprc_v2.for_genbank.ont_r10_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_ont_r10/
mkdir -p "$OUTDIR"

link_hmm_flagger_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>hg002_flagger_upload.stderr


###############################################################################
##                        Also Upload Haploid Results                        ##
###############################################################################

link_hmm_flagger_hap_outputs() {
  local json="$1"
  local outdir="$2"

  mkdir -p "$outdir"

  local keys=(
    finalPredictionBedConservativeHap1
    finalPredictionBedConservativeHap2
    finalPredictionBedHap1
    finalPredictionBedHap2
  )

  for key in "${keys[@]}"; do
    jq -r --arg key "$key" '
      to_entries[]
      | select(.key | endswith($key))
      | .value
      | if type == "array" then .[] else . end
      | select(. != null)
    ' "$json" | while read -r file; do
      
      # skip if file doesn't exist (optional safety)
      if [[ -e "$file" ]]; then
        ln -sf "$file" "$outdir/$(basename "$file")"
      else
        echo "WARNING: missing file for $key -> $file" >&2
      fi

    done
  done
}

cd /private/groups/hprc/qc_testing/hg002_qc_comparison/flagger/hifi/s3_upload


JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.hifi/HG002.hprc_v2.for_genbank.hifi_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload_hap/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_hifi/
mkdir -p "$OUTDIR"

link_hmm_flagger_hap_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload_hap \
    &>>hg002_flagger_hifi_hap_upload.stderr



cd /private/groups/hprc/qc_testing/hg002_qc_comparison/flagger/ont_r9/s3_upload

JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.ont_r9/HG002.hprc_v2.for_genbank.ont_r9_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload_hap/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_ont_r9/
mkdir -p "$OUTDIR"

link_hmm_flagger_hap_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload_hap \
    &>>hg002_flagger_hap_upload.stderr




cd /private/groups/hprc/qc_testing/hg002_qc_comparison/flagger/ont_r10/s3_upload

JSON=/private/groups/patenlab/masri/hmm_flagger_hg002_hprc_v2/runs_toil_slurm/HG002.hprc_v2.for_genbank.ont_r10/HG002.hprc_v2.for_genbank.ont_r10_hmm_flagger_end_to_end_with_mapping_outputs.json
OUTDIR=upload_hap/HG002/assemblies/freeze_2/assembly_pipeline/ncbi_upload/assembly_qc/hmm_flagger/v1.2.0_ont_r10/
mkdir -p "$OUTDIR"

link_hmm_flagger_hap_outputs \
  "$JSON" \
  "$OUTDIR"

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload_hap \
    &>>hg002_flagger_hap_upload.stderr



###############################################################################
##                                DONE                                       ##
###############################################################################