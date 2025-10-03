#!/bin/bash

# Usage: bash run_freesurfer1.sh
# To run even if remote computer disconnects: nohup bash run_freesurfer_mprage1.sh >output_mprage1.log 2>&1 &

# set directory for freesurfer output
export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/test_resample_mprage/freesurfer_output 

while read filepath; do

	echo "Processing file: ${filepath}"

 	dir=$(dirname "${filepath}")
	filename=$(basename "${filepath}")
	base="${filename%.nii.gz}"
	parent_dir=$(basename "${dir}")

	input_file="${dir}/${filename}"

	# Construct a unique subject ID using directory name
	subject_id="${parent_dir}_${base}_freesurfer"

	# Skip this subject if already processed
	if [ -d "${SUBJECTS_DIR}/${subject_id}" ]; then
	   echo "Subject ${subject_id} already processed, skipping..."
	   continue
	fi
	
	# Run freesurfer
        echo "Running freesurfer"	
	recon-all -i "${input_file}" -s "${subject_id}" -all -parallel 

done < subjectstorun_mprage1.txt
	
