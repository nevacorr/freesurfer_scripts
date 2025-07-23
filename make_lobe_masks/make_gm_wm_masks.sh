#!/bin/bash

# Usage bash make_gm_wm_masks.sh

SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output/
LOBE_MASK_DIR=/home/toddr/neva/MPF/make_lobe_masks/combined_masks

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

	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_left.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" --match 2 5001 --o "$out_mask"

	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_right.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" --match 41 5002 --o "$out_mask"

	out_mask="$LOBE_MASK_DIR/$SUBJECT/cerebrum_wm_bilat.mgz"
	mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" --match 2 41 251 252 253 254 255  5001 5002 --o "$out_mask"

done <subjects_list.txt
