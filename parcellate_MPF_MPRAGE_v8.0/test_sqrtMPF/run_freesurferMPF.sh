#!/bin/bash

# Usage: bash run_freesurferMPF.sh

# set directory for freesurfer output
export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/test_sqrtMPF/freesurfer_output 

# Set output directory for nifti and flipped images
OUTPUT_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/test_sqrtMPF/nifti_outputs
mkdir -p "${OUTPUT_DIR}"

# Load sform/qform from reference image
sform_matrix=$(fslorient -getsform MT.nii)
qform_matrix=$(fslorient -getqform MT.nii)
read -r -a sform_array <<< "$sform_matrix"
read -r -a qform_array <<< "$qform_matrix"

while read filepath; do

	echo "Processing file: ${filepath}"

 	dir=$(dirname "${filepath}")
	filename=$(basename "${filepath}")
	base="${filename%.nii.gz}"
	parent_dir=$(basename "${dir}")

	input_file="${dir}/${filename}"	
	output_base="${OUTPUT_DIR}/${parent_dir}_${base}"	
	flipped_file="${output_base}_flipped.nii.gz"
	
	# Construct a unique subject ID using directory name
	subject_id="${parent_dir}_${base}_freesurfer"

	# Skip this subject if already processed
	if [ -d "${SUBJECTS_DIR}/${subject_id}" ]; then
	   echo "Subject ${subject_id} already processed, skipping..."
	   continue
	fi

	#Clean up old files
	rm -rf "${flipped_file}"

	# Swap axes
	echo "Swapping axes"	
	fslswapdim "${input_file}" -z -x -y "${flipped_file}"

	# Apply orientation from reference
	echo "Applying orientation from reference MT.nii"
	fslorient -setsform "${sform_array[@]}" "${flipped_file}"
	fslorient -setqform "${qform_array[@]}" "${flipped_file}"
	fslorient -setsformcode 1 "${flipped_file}"
	fslorient -setqformcode 1 "${flipped_file}"
	
	# Run freesurfer
        echo "Running freesurfer"	
	recon-all -i "${flipped_file}" -s "${subject_id}" -noskullstrip -all -parallel 

done < subjectstorunMT.txt
	
