#!/bin/bash

# This script processes FreeSurfer aparc+aseg.mgz files that have been registered 
# to the MPRAGE space for one or more subjects. For each registered file, it 
# generates a corresponding aseg.stats-like file using mri_segstats. 
# The output stats files contain voxel counts and volumes for all FreeSurfer regions
# in the same voxels grid as teh MPRAGE enabling accuate comparison of regional
# volumes across modalities 
 
# Usage: bash register_aseg_stats.sh <aseg+aparc_reg_to_mprage.mgz file path>

if [ $# -ne 1 ]; then
	echo "Usage: $0 <folder_with_registered_aparc+aseg.mgz_files>"
	exit 1
fi

INPUT_FOLDER=$1
OUTPUT_DIR="aseg_output"

mkdir -p "$OUTPUT_DIR"

# Loop over all MGZ files in the input folder
for MGZ_file in "$INPUT_FOLDER"/*_aparc+aseg_reg_to_mprage.mgz; do
	# Skip files that start with "brain_"
	if [[ $(basename "$MGZ_file") == brain_* ]]; then
		echo "Skipping $MGZ_file (starts with brain_)"
		continue
	fi

	if [ ! -f "$MGZ_file" ]; then
		echo "No files found in $INPUT_FOLDER, skipping."
		continue
	fi	

	# Extract basename without path or extension
	BASE_NAME=$(basename "$MGZ_file" .mgz)

	# Generate stats file
	mri_segstats --seg "$MGZ_file" --sum ${OUTPUT_DIR}/${BASE_NAME}_MPF_in_MPRAGE.stats

	echo "Generated stats for $BASE_NAME -> $OUTPUT_DIR/${BASE_NAME}_MPF_in_MPRAGE.stats"
done

echo "All stats files saved in $OUTPUT_DIR/"
