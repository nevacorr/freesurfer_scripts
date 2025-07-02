#!/bin/bash

# Compare across-modality scans (MPRAGE-MPF) using Dice and Jaccard similarity coefficients 

# Usage: nohup bash compute_jaccard_dice_mprage_mpf.sh > compute_jaccard_mprage_mpf.log 2>&1 &

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output
OUTPUT_FILE="mprage_mpf_overlap_summary.csv"
TMP_DIR="./tmp_coreg_mpfmprage"

mkdir -p "$TMP_DIR"

# Function to coregister aparc+aseg.mgz from two separate sessions of same subject
coregister_pair() {

	echo "##########################Running new subject ############################"
	local subj_id=$1
	local tp=$2

	local mprage_dir="$SUBJECTS_DIR/${subj_id}-${tp}_mprage1_freesurfer"
	local mpf_dir="$SUBJECTS_DIR/${subj_id}-${tp}_MPFcor_freesurfer"

	local aseg_mprage="$mprage_dir/mri/aparc+aseg.mgz"
	local aseg_mpf="$mpf_dir/mri/aparc+aseg.mgz"
	local rawavg_mprage="$mprage_dir/mri/rawavg.mgz"
	local rawavg_mpf="$mpf_dir/mri/rawavg.mgz"

        local regfile="${TMP_DIR}/${subj_id}_tp${tp}_mpf2mprage.lta"
	local aseg_mpf_coreg="${TMP_DIR}/${subj_id}_tp${tp}_aseg_mpf_coreg.mgz"
	local rawavg_mprage_stripped="${TMP_DIR}/${subj_id}_tp${tp}_mprage_rawavg_stripped.mgz"

	if [[ -f "$aseg_mprage" && -f "$aseg_mpf" && -f "$rawavg_mprage" && -f "$rawavg_mpf" ]]; then
		echo "Registering MPF to MPRAGE for $subj_id "

		echo $rawavg_mprage
		echo $mprage_dir/mri/brainmask.mgz
		echo $rawavg_mprage_stripped

		mri_mask "$rawavg_mprage" "$mprage_dir/mri/brainmask.mgz" "$rawavg_mprage_stripped"

		# Compute tranforms to align rawvg mpf to rawavg mprage
		mri_robust_register --mov "$rawavg_mpf" \
			--dst "$rawavg_mprage_stripped" \
			--lta "$regfile" \
			--satit

		# Apply tranform to aseg mpf to resampel into rawavg mprage space	
		mri_vol2vol --mov "$aseg_mpf" \
			    --targ "$aseg_mprage" \
			    --lta "$regfile" \
			    --o "$aseg_mpf_coreg" \
			    --interp nearest
	
		echo "Saved: $aseg_mpf_coreg"
	else
		echo "Skipping coregistration for $subj_id T$tp (missing input files)"
	fi
}

# Loop over all subjects and coregister
for tp in 1 2; do
	for mprage in "$SUBJECTS_DIR"/H??-"$tp"_mprage1_freesurfer; do
		subj_id=$(basename "$mprage" | sed "s/-${tp}_mprage1_freesurfer//")
		mpf="$SUBJECTS_DIR/${subj_id}-${tp}_MPFcor_freesurfer"
		if [[ -d "$mpf" ]]; then
			coregister_pair "$subj_id" "$tp"
		fi
	done        
done

echo "Coregistration for all subjects complete"
echo "------------------------------------------------------"

# Extract label names from first usable pair
for tp in 1 2; do
	for mprage in "$SUBJECTS_DIR"/H??-"$tp"_mprage1_freesurfer; do
		subj_id=$(basename "$mprage" | sed "s/-${tp}_mprage1_freesurfer//")
		aseg1="$mprage/mri/aparc+aseg.mgz"
		aseg2="${TMP_DIR}/${subj_id}_tp${tp}_aseg_mpf_coreg.mgz"

		if [[ -f "$aseg1" && -f "$aseg2" ]]; then
			echo "Extracting label list from $subj_id timepoint $tp"	
			mapfile -t LABELS < <(mri_seg_overlap --measures dice jaccard "$aseg1" "$aseg2" | awk 'NR>1 {print $2}')
			break
		fi
	done
done

# Build outputfile header
header="SubjectID,Timepoint"
for label in "${LABELS[@]}"; do 
	header+=",DICE_$label,JACCARD_$label"
done
echo "$header" > "$OUTPUT_FILE"


# Function to calculate overlap between parcellations and compute DICE and Jaccard coefficients

calculate_overlap() {

	local subj_id=$1
	local tp=$2

	local mprage_dir="$SUBJECTS_DIR/${subj_id}-${tp}_mprage1_freesurfer"
	local aseg_mprage="$mprage_dir/mri/aparc+aseg.mgz"
        local aseg_mpf_coreg="${TMP_DIR}/${subj_id}_tp${tp}_aseg_mpf_coreg.mgz"

	if [[ -f "$aseg_mprage" && -f "$aseg_mpf_coreg" ]]; then
		echo "Calculating Dice/Jaccard for $subj_id timepoint $tp"

		overlap_output=$(mri_seg_overlap --measures dice jaccard "$aseg_mprage" "$aseg_mpf_coreg")

		line="$subj_id,T${tp}"
		while read -r label dice jaccard; do
			line+=",${dice},${jaccard}"
		done < <(echo "$overlap_output" | awk 'NR>1 {print $2, $3, $4}')

		echo "$line" >> "$OUTPUT_FILE"
	
	else
		echo "Missing input for overlap: $subj_id T$tp"
	fi
}

# Loop to calculate overlap
for tp in 1 2; do
	for mprage in "$SUBJECTS_DIR"/H??-"$tp"_mprage1_freesurfer; do
		subj_id=$(basename "$mprage" | sed "s/-${tp}_mprage1_freesurfer//")
		echo "subj_id" $subj_id
		calculate_overlap "$subj_id" "$tp"
	done
done


