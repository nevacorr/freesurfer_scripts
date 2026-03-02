#!/bin/bash

## Usage: 
##conda activate ants
##nohup bash register_VFA2_MNI.sh >ants_registration.log 2>&1 &

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8

## Exit code on error
set -e

# Reference image for orientation/registration
FIXED=files_from_vasily/MNI152_T1_1mm_brain-better-aligned.nii.gz

# Output folder
OUT_ROOT=SEG_REPRO_reg_to_MNIadj

# Input base folder
#INPUT_ROOT=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/SEG_REPRO
INPUT_ROOT=/home/toddr/neva/MPF/register_SMATT_to_MPF/mpf2MNI_nodura/SEG_REPRO_reg

# Find all the H* subfolders
for H_FOLDER in "$INPUT_ROOT"/H*; do
	echo ${H_FOLDER}
	if [ -d "$H_FOLDER" ]; then
		HNAME=$(basename "$H_FOLDER")
		echo "${HNAME} FOUND!"		
		# Create output folder for this subject
	        OUT_SUBFOLDER="$OUT_ROOT/$HNAME"
		mkdir -p "$OUT_SUBFOLDER"

		INPUT_IMG="$H_FOLDER/MPFcor.hdr"
				
		if [ ! -f "$INPUT_IMG" ]; then
			echo "Skipping missing $INPUT_IMG in $HH_FOLDER"
			continue
		fi

		echo "INPUT_IMG found!"
		BASE=$(basename "$H_FOLDER")
		FLIPPED_IMG="$OUT_SUBFOLDER/${BASE}_flipped.nii.gz"
		FLIPPED_N4_IMG="$OUT_SUBFOLDER/${BASE}_flipped_N4.nii.gz"
		MASKED_FLIPPED_N4_IMG="$OUT_SUBFOLDER/${BASE}_flipped_N4_nodura.nii.gz"
		OUT="$OUT_SUBFOLDER/${BASE}_masked_2_mniadj_"
		MPF_REG_TO_MNI="$OUT_SUBFOLDER/${BASE}_reg_to_mni_adj.nii.gz"
		MOVING="$MASKED_FLIPPED_N4_IMG"

		## Load sform/qform from reference image
		sform_matrix=$(fslorient -getsform MT.nii)
		qform_matrix=$(fslorient -getqform MT.nii)
		read -r -a sform_array <<< "$sform_matrix"
		read -r -a qform_array <<< "$qform_matrix"

		echo "Converting $INPUT_IMG  from analyze to nifti format"
		fslchfiletype NIFTI_GZ "$INPUT_IMG" "$OUT_SUBFOLDER/${BASE}.nii.gz"

		echo "Swapping axes"	
		fslswapdim "$OUT_SUBFOLDER/${BASE}.nii.gz" -z -x -y "$FLIPPED_IMG"

		echo "Applying orientation from reference MT.nii"
		fslorient -setsform "${sform_array[@]}" "$FLIPPED_IMG"
		fslorient -setqform "${qform_array[@]}" "$FLIPPED_IMG"
		fslorient -setsformcode 1 "$FLIPPED_IMG"
		fslorient -setqformcode 1 "$FLIPPED_IMG"

		echo "Performing bias field correction"
		N4BiasFieldCorrection -d 3 -i "$FLIPPED_IMG" -o "$FLIPPED_N4_IMG"

		echo "Generating mask for Atropos"
		fslmaths "$FLIPPED_N4_IMG" -bin "$OUT_SUBFOLDER/N4_mask.nii.gz"

		echo "Segmenting with Atropos"
		Atropos -d 3 -a "$FLIPPED_N4_IMG" -x "$OUT_SUBFOLDER/N4_mask.nii.gz" \
			-c [5,0.0001] -i kmeans[3] \
			-o ["$OUT_SUBFOLDER/segmentation.nii.gz","$OUT_SUBFOLDER/prob%02d.nii.gz"]

		echo "Summing GM and WM volumes"
		fslmaths "$OUT_SUBFOLDER/prob02.nii.gz" -add "$OUT_SUBFOLDER/prob03.nii.gz" -thr 0.5 -bin "$OUT_SUBFOLDER/MPF_brain_prob_bin.nii.gz"

		echo "Eroding mask"
		fslmaths "$OUT_SUBFOLDER/MPF_brain_prob_bin.nii.gz" -ero "$OUT_SUBFOLDER/MPF_brain_prob_bin_ero.nii.gz"

		echo "Dilating mask"
		fslmaths "$OUT_SUBFOLDER/MPF_brain_prob_bin_ero.nii.gz" -dilM "$OUT_SUBFOLDER/MPF_brain_prob_bin_ero_dil.nii.gz"

		echo "Applying no dura mask to N4 image"
		fslmaths "$FLIPPED_N4_IMG" -mas "$OUT_SUBFOLDER/MPF_brain_prob_bin_ero_dil.nii.gz"  "$MASKED_FLIPPED_N4_IMG"


		echo "Running ants registration"
		antsRegistration \
		 --dimensionality 3 \
		 --float 0 \
		 --output ["$OUT","${OUT}Warped.nii.gz"] \
		 --interpolation Linear \
		 --winsorize-image-intensities [0.005, 0.995] \
		 --use-histogram-matching 1 \
		 --initial-moving-transform ["$FIXED","$MOVING",1] \
		 --transform Rigid[0.1] \
		   --metric Mattes["$FIXED","$MOVING",1,32,Regular,0.25] \
		   --convergence [1000x500x250x0,1e-6,10] \
		   --shrink-factors 8x4x2x1 \
		   --smoothing-sigmas 3x2x1x0vox \
		 --transform Affine[0.1] \
		   --metric Mattes["$FIXED","$MOVING",1,32,Regular,0.25] \
		   --convergence [100x70x50x20,1e-6,10] \
		   --shrink-factors 8x4x2x1 \
		   --smoothing-sigmas 3x2x1x0vox \
		 --transform SyN[0.1,3,0] \
		   --metric Mattes["$FIXED","$MOVING",1,32] \
		   --convergence [100x70x50x20,1e-6,10] \
		   --shrink-factors 8x4x2x1 \
		   --smoothing-sigmas 3x2x1x0vox


		antsApplyTransforms -d 3 \
		 -i "$FLIPPED_IMG" \
		 -r "$FIXED" \
		 -o "$MPF_REG_TO_MNI" \
		 -n Linear \
		 -t "${OUT}1Warp.nii.gz" \
		 -t "${OUT}0GenericAffine.mat"
	fi
done		
			
