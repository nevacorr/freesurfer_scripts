#!/bin/bash

# Compute Dice and Jaccard similarity coefficients for MPF and MPRAGE obtained in same session

# Usage: bash compute_jaccard_dice_mprage_mpf.sh

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output
OUTPUT_FILE="mprage_mpf_seg_overlap_summary.csv"

# Find first valid pair to extract list of label names

for mprage_dir in "$SUBJECTS_DIR"/H??-?_mprage1_freesurfer; do
	subj_id=$(basename "$mprage_dir" | cut -d'_' -f1)

        echo "Subject ID: $subj_id"	

	mpf_dir="$SUBJECTS_DIR/${subj_id}_MPFcor_freesurfer"

	aseg1="$mprage_dir/mri/aparc+aseg.mgz"
	aseg2="$mpf_dir/mri/aparc+aseg.mgz"

	if [[ -f "$aseg1" && -f "$aseg2" ]]; then
		echo "Extracting label list from $subj_id"	
		mapfile -t LABELS < <(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2" | awk 'NR>1 {print $2}')
		break
	fi
done

# Build outputfile header
header="SubjectID"
for label in "${LABELS[@]}"; do 
	header+=",DICE_$label,JACCARD_$label"
done
echo "$header" > "$OUTPUT_FILE"

# Loop over all subjects
for mprage_dir in "$SUBJECTS_DIR"/H??-?_mprage1_freesurfer; do
	subj_id=$(basename "$mprage_dir" | cut -d'_' -f1)
	mpf_dir="$SUBJECTS_DIR/${subj_id}_MPFcor_freesurfer"

        echo "Processing Subject ID: $subj_id"	
	
	if [[ -d "$mpf_dir" ]]; then

		aseg1="$mprage_dir/mri/aparc+aseg.mgz"
		aseg2="$mpf_dir/mri/aparc+aseg.mgz"

		if [[ -f "$aseg1" && -f "$aseg2" ]]; then
			echo "Running mri_seg_overlap for $subj_id"

			# Run mri_seg_overlap and capture output
			overlap_output=$(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2")
			
			line="$subj_id"

			while read -r label dice jaccard; do
				line+=",$dice,$jaccard"
			done < <(echo "$overlap_output" | awk 'NR>1 {print $2, $3, $4}')

			echo "$line" >> "$OUTPUT_FILE"
		else
			echo "Skipping $subj_id (missing aparc+aseg.mgz)"
		fi
	else
		echo "No MPFcor directory for $subj_id - skipping"
	fi
done

echo "Finished. Table saved to $OUTPUT_FILE"	
