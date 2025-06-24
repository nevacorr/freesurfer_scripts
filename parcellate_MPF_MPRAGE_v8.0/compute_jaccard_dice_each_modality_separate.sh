#!/bin/bash

# Compare within-modality scans (MPRAGE-MPRAGE and MPF-MPF) using Dice and Jaccard similarity coefficients 

# Usage: bash compute_jaccard_dice_each_modality_separate.sh

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output
OUTPUT_FILE="within_modality_overlap_summary.csv"

# Find a valid subject pair to extract list of label names

for dir1 in "$SUBJECTS_DIR"/H??-1_mprage1_freesurfer; do

	subj_id=$(basename "$dir1" | sed 's/-1_mprage1_freesurfer//')
	dir2="$SUBJECTS_DIR/${subj_id}-2_mprage1_freesurfer"

	aseg1="$dir1/mri/aparc+aseg.mgz"
	aseg2="$dir2/mri/aparc+aseg.mgz"

	if [[ -f "$aseg1" && -f "$aseg2" ]]; then
		echo "Extracting label list from $subj_id"	
		mapfile -t LABELS < <(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2" | awk 'NR>1 {print $2}')
		break
	fi
done

# Build outputfile header
header="SubjectID,Modality"
for label in "${LABELS[@]}"; do 
	header+=",DICE_$label,JACCARD_$label"
done
echo "$header" > "$OUTPUT_FILE"

# Function to compare two freesurfer outputs
compare_pair() {
	local subj_id=$1
	local modality=$2
	local dir1=$3
	local dir2=$4

	aseg1="$dir1/mri/aparc+aseg.mgz"
	aseg2="$dir2/mri/aparc+aseg.mgz"

	if [[ -f "$aseg1" && -f "$aseg2" ]]; then
		echo "Comparing $modality for $subj_id"

		overlap_output=$(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2")

		line="$subj_id,$modality"
		while read -r label dice jaccard; do
			line+=",$dice,$jaccard"
		done < <(echo "$overlap_output" | awk 'NR>1 {print $2, $3, $4}')

		echo "$line" >> "$OUTPUT_FILE"
	else
		echo "Skipping $subj_id (missing aparc+aseg.mgz for $modality)"
	fi
}

# Loop over all subjects and compare MPRAGE scans
for mprage1 in "$SUBJECTS_DIR"/H??-1_mprage1_freesurfer; do
	subj_id=$(basename "$mprage1" | sed 's/-1_mprage1_freesurfer//')
	mprage2="$SUBJECTS_DIR/${subj_id}-2_mprage1_freesurfer"
	if [[ -d "$mprage1" && -d "$mprage2" ]]; then
		compare_pair "$subj_id" "MPRAGE" "$mprage1" "$mprage2"
	fi        
done

# Loop over all subjects and compare MPF scans
for mpf1 in "$SUBJECTS_DIR"/H??-1_MPFcor_freesurfer; do
	subj_id=$(basename "$mpf1" | sed 's/-1_MPFcor_freesurfer//')
	mpf2="$SUBJECTS_DIR/${subj_id}-2_MPFcor_freesurfer"

	if [[ -d "$mpf1" && -d "$mpf2" ]]; then
		compare_pair "$subj_id" "MPFcor" "$mpf1" "$mpf2"
	fi        
done

echo "Finished. Table saved to $OUTPUT_FILE"	
