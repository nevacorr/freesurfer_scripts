#!/bin/bash

# Compare within-modality scans (MPRAGE-MPRAGE and MPF-MPF) using Dice and Jaccard similarity coefficients 

# Usage: bash compute_jaccard_dice_each_modality_separate.sh

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output
OUTPUT_FILE="within_modality_overlap_summary.csv"
TMP_DIR="./tmp_coreg"
mkdir -p "$TMP_DIR"

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

# Function to coregister aparc+aseg.mgz from two separate sessions of same subject
coregister_pair() {

	echo "##########################Running new subject ############################"
	local subj_id=$1
	local modality=$2
	local dir1=$3
	local dir2=$4

	aseg1="$dir1/mri/aparc+aseg.mgz"
	aseg2="$dir2/mri/aparc+aseg.mgz"
	rawavg1="$dir1/mri/rawavg.mgz"
	rawavg2="$dir2/mri/rawavg.mgz"

        regfile="${TMP_DIR}/${subj_id}_${modality}_reg.lta"
	aseg2_coreg="${TMP_DIR}/tmp_${subj_id}_${modality}_aseg2_coreg.mgz"

	echo "aseg1" "$aseg1"
	echo "aseg2" "$aseg2"
	echo "rawavg1" "$rawavg1"
	echo "rawavg2" "$rawavg2"

	if [[ -f "$aseg1" && -f "$aseg2" && -f "$rawavg1" && -f "$rawavg2" ]]; then
		echo "Registering #modality scan 2 to scan 1 for $subj_id "

		# Compute tranforms to align rawvg2 to rawavg1
		mri_coreg --mov "$rawavg2" --ref "$rawavg1" --reg "$regfile" 

		# Apply tranform to aseg2 to resampel into rawavg1 space	
		mri_vol2vol --mov "$aseg2" \
			    --targ "$rawavg1" \
			    --reg "$regfile" \
			    --o "$aseg2_coreg" \
			    --interp nearest

	else
		echo "Skipping $subj_id (missing aseg or rawavg)"
	fi
}

# Loop over all subjects and compare MPRAGE scans
for mprage1 in "$SUBJECTS_DIR"/H??-1_mprage1_freesurfer; do
	subj_id=$(basename "$mprage1" | sed 's/-1_mprage1_freesurfer//')
	echo "subj_id" $subj_id
	mprage2="$SUBJECTS_DIR/${subj_id}-2_mprage1_freesurfer"
	if [[ -d "$mprage1" && -d "$mprage2" ]]; then
		coregister_pair "$subj_id" "MPRAGE" "$mprage1" "$mprage2"
	else
		echo Cannot coregister $subj_id $mprage1 $mprage2
	fi        
done

# Loop over all subjects and compare MPF scans
for mpf1 in "$SUBJECTS_DIR"/H??-1_MPFcor_freesurfer; do
	subj_id=$(basename "$mpf1" | sed 's/-1_MPFcor_freesurfer//')
	mpf2="$SUBJECTS_DIR/${subj_id}-2_MPFcor_freesurfer"

	if [[ -d "$mpf1" && -d "$mpf2" ]]; then
		coregister_pair "$subj_id" "MPFcor" "$mpf1" "$mpf2"
	fi        
done

# Function to calcualte overlap between parcellations and compute DICE and Jaccard coefficients

calculate_overlap() {

	local subj_id=$1
	local modality=$2
	local dir1=$3

	aseg1="$dir1/mri/aparc+aseg.mgz"
	aseg2_coreg="${TMP_DIR}/tmp_${subj_id}_${modality}_aseg2_coreg.mgz"

	if [[ -f "$aseg1" && -f "$aseg2_coreg" ]]; then
		echo "Calculating Dice/Jaccard for $modality $subj_id"

		overlap_output=$(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2_coreg")

		line="$subj_id,$modality"
		while read -r label dice jaccard; do
			line+=",$dice,$jaccard"
		done < <(echo "$overlap_output" | awk 'NR>1 {print $2, $3, $4}')

		echo "$line" >> "$OUTPUT_FILE"
	
	else
		echo "Missing input for $subj_id $modality"
	fi
}

# Loop over all subjects and calculate overlap for MPRAGE scans
for mprage1 in "$SUBJECTS_DIR"/H??-1_mprage1_freesurfer; do
	subj_id=$(basename "$mprage1" | sed 's/-1_mprage1_freesurfer//')
	echo "subj_id" $subj_id
	calculate_overlap "$subj_id" "MPRAGE" "$mprage1" 
done

# Loop over all subjects and calculate overlap for MPF scans
for mpf1 in "$SUBJECTS_DIR"/H??-1_MPFcor_freesurfer; do
	subj_id=$(basename "$mpf1" | sed 's/-1_MPFcor_freesurfer//')
	calculate_overlap "$subj_id" "MPFcor" "$mpf1" 
done

