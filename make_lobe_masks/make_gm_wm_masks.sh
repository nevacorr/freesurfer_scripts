#!/bin/bash

# Usage bash make_gm_wm_masks.sh

SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output/
LOBE_MASK_DIR=/home/toddr/neva/MPF/make_lobe_masks/combined_masks
LABEL_DIR=/home/toddr/neva/MPF/make_lobe_masks/lobe_roi_lists

# Read wm labels
readarray -t wm_lh_labels < "$LABEL_DIR/cerebrum_wm_lh.txt"
readarray -t wm_rh_labels < "$LABEL_DIR/cerebrum_wm_rh.txt"
readarray -t wm_bilat_labels < "$LABEL_DIR/cerebrum_wm_bilat.txt"

while read -r SUBJECT; do

	if [ -z "$SUBJECT" ]; then
		echo "Error: subject not recognized"
		exit 1
	fi

	echo "Processing subject: $SUBJECT"

	mkdir -p "$LOBE_MASK_DIR/$SUBJECT"

	# Make gray matter masks from ribbon
	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_gm_left.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/ribbon.mgz" --match 3 --o "$out_mask"

	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_gm_right.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/ribbon.mgz" --match 42 --o "$out_mask"

	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_gm_bilat.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/ribbon.mgz" --match 3 42 --o "$out_mask"

	# Make white matter masks using label numbers from file

	matches=()
	for label in "${wm_lh_labels[@]}"; do
		matches+=(--match "$label")
	done	
	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_left.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" "${matches[@]}" --o "$out_mask"

	matches=()
	for label in "${wm_rh_labels[@]}"; do
		matches+=(--match "$label")
	done	
	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_right.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" "${matches[@]}" --o "$out_mask"

	matches=()
	for label in "${wm_bilat_labels[@]}"; do
		matches+=(--match "$label")
	done	
	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_bilat.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" "${matches[@]}" --o "$out_mask"

done <subjects_list.txt
