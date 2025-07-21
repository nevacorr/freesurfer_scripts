#!/bin/bash

SUBJECT=$1
SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output/
LOBE_MASK_DIR=/home/toddr/neva/MPF/make_lobe_masks/
ROILIST_DIR=./lobe_roi_lists

mkdir -p "$LOBE_MASK_DIR/$SUBJECT"

lobes=("frontal" "parietal" "temporal" "occipital")
hemis=("left" "right")
tissues=("gm" "wm")

for lobe in "${lobes[@]}"; do
	for tissue in "${tissues[@]}"; do
		for hemi in "${hemis[@]}"; do
			roi_file="$ROILIST_DIR/${lobe}_${tissue}_${hemi}.txt"
			out_mask="$LOBE_MASK_DIR/$SUBJECT/${lobe}_${tissue}_${hemi}.mgz"

			if [ ! -f "$roi_file" ]; then
				echo "ROI file not found: $roi_file"
				continue
			fi

			# Read all labels from the ROI file 
			labels=$(tr '\n' ' ' < "$roi_file")
			
			echo "Creating mask: $out_mask"
			mri_binarize --i "$SUBJECTS_DIR/$SUBJECT/mri/wmparc.mgz" \
				     --match $labels \
				     --o "$out_mask"
		done

		# Combine left and right masks into bilateral mask
		left_mask="$LOBE_MASK_DIR/$SUBJECT/${lobe}_${tissue}_left.mgz"  
		right_mask="$LOBE_MASK_DIR/$SUBJECT/${lobe}_${tissue}_right.mgz"  
		bilat_mask="$LOBE_MASK_DIR/$SUBJECT/${lobe}_${tissue}_bilat.mgz" 
		mri_or -i "$left_mask" --i2 "$right_mask" --o "$bilat_mask" 

	done
done

