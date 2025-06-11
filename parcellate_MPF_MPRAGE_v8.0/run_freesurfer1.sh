#!/usr/bin/bash

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output # set directory for freesurfer output

	while read filepath
	do

		echo "Processing file: ${filepath}"

		#Get directory path and filename without extension
	 	dir=$(dirname "${filepath}")
		base=$(basename "${filepath}" .hdr)

		# Define output .nii file path
		nii_file="${dir}/${base}.nii"

		# Convert .hdr/.img file to .nii
		echo "Converting ${filepath} to ${nii_file} with fslchfiletype"
		input_base="${dir}/${base}"
	        fslchfiletype NIFTI "${input_base}" "${nii_file}"

		# Perform parcellation with freesurfer
#		recon-all -i "${nii_file}" -s ${base}_freesurfer -all -parallel

	done < subjectstorun1.txt
	
