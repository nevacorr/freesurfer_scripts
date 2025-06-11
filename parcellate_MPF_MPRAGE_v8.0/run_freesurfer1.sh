#!/usr/bin/bash

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output # set directory for freesurfer output

	while read filepath
	do

		echo "Processing file: ${filepath}"

		#Get directory path and filename without extension
	 	dir=$(dirname "${filepath}")
		base=$(basename "${filepath}" .hdr)

		# Get last directory name as a unique prefix
		parent_dir=$(basename "${dir}")
	
		# Define output .nii file path
		nii_file="${dir}/${base}.nii"

		# Convert .hdr/.img file to .nii
		echo "Converting ${filepath} to ${nii_file} with fslchfiletype"
		input_base="${dir}/${base}"
	        fslchfiletype NIFTI "${input_base}" "${nii_file}"

		# Construct a unique subject ID using directory name
		subj_id="${parent_dir}_${base}_freesurfer"

		rm -rf "${SUBJECTS_DIR}/${subj_id}"

		# Perform parcellation with freesurfer
		recon-all -i "${nii_file}" -s ${subj_id} -all -parallel

	done < subjectstorun1.txt
	
