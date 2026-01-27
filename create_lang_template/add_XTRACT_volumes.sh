#!/bin/bash

set -euo pipefail #return an error if any command fails

ATLAS_DIR=~/Documents/MPF_Project/XTRACT_WM_Atlas/XTRACT_atlases-master

TRACT_DIR="${ATLAS_DIR}/HCP_tracts_5" 

TRACTS=("ilf" "ifo" "mdlf" "uf" "af" "slf1" "slf2" "slf3")

THR=0.7 #probability threshold for inclusion of voxels in template

for HEMI in l r; do

	if [ "$HEMI" = "l" ]; then
		OUT="lang_xtract_atlas_left.nii.gz"
	else
		OUT="lang_xtract_atlas_right.nii.gz"
	fi

	SUM_IMAGE="${TRACT_DIR}/${OUT}"
	rm -f "$SUM_IMAGE"

	for TRACT in "${TRACTS[@]}"; do

		BIN="${TRACT_DIR}/${TRACT}_${HEMI}_bin70.nii.gz"

		#apply threshold and binarize
		fslmaths "${TRACT_DIR}/${TRACT}_${HEMI}.nii.gz" \
		    -thr $THR -bin "$BIN"

		#sum binary masks
		if [ ! -f "$SUM_IMAGE" ]; then
			cp "$BIN" "$SUM_IMAGE"
		else
			fslmaths "$SUM_IMAGE" -add "$BIN" "$SUM_IMAGE"
		fi
	done

	# final binary mask (0 and 1 values only, the above creates
	# a mask with values >1 when more than one tract includes a voxel) 
	fslmaths "$SUM_IMAGE" -bin "${TRACT_DIR}/${OUT}"

	rm -f "$SUM_IMAGE"
	rm -f "$BIN"

done
