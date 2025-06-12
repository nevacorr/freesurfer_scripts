#!/usr/bin/bash

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output # set directory for freesurfer output

while read filepath; do

	echo "Processing file: ${filepath}"

	#Get directory path and filename without extension
 	dir=$(dirname "${filepath}")
	base=$(basename "${filepath}" .hdr)

	# Get last directory name as a unique prefix
	parent_dir=$(basename "${dir}")
	
	# Define output .nii file path
	nii_file="${dir}/${base}.nii"
	
	# Construct a unique subject ID using directory name
	subj_id="${parent_dir}_${base}_freesurfer"
	subject_dir="${SUBJECTS_DIR}/${subj_id}"

	if [ -f "${nii_file}" ]; then
		echo "NIFTI file ${nii_file} already exists, skipping conversion"
	else
		# Convert .hdr/.img file to .nii
		echo "Converting ${filepath} to ${nii_file} with fslchfiletype"
		input_base="${dir}/${base}"
        	fslchfiletype NIFTI "${input_base}" "${nii_file}"
	fi

	# Remove previous freesurfer output for this subject if it exists
	rm -rf "${subject_dir}"
	mkdir -p "${subject_dir}/mri/orig"

	# Converting .ni to 001.mgz for FreeSurfer input
	mri_convert "${nii_file}" "${subject_dir}/mri/orig/001.mgz"

	# Run custom normalization for MPRAGE input
	mri_normalize -mprage -b 20 -n 5 \
 		"${subject_dir}/mri/orig/001.mgz" \
		"${subject_dir}/mri/nu.mgz"

	# Create expected symbolic link
	ln -sf "${subject_dir}/mri/orig/001.mgz" "${subject_dir}/mri/orig.mgz"

	read -p "Press Enter to continue to recon-all (or Ctrl+C to cancel)..."	
	
	# Run recon-all from autorecon2 using custom normalization 
	recon-all -subjid "${subj_id}" -autorecon2 -autorecon3 -parallel

done < subjectstorun1.txt
	
