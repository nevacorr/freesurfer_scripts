#!/bin/bash

# This script loops through all FreeSurfer output directories for MPF data, registers each subject's original MPF volume (001.mgz) to their rawavg.mgz
# using mri_robust_register, applies the resulting tranform to align the MPF volume to the subject's aparc+aseg segmentation and then uses mri_segstats
# to extract mean MPF values for all cortical and subcortical parcels. 
# Note: We register the original MPF volume (001.mgz) to rawavg.mgz because FreeSurfer's anatomical segmentation (aparc+aseg.mgz) is defined in the 
# rawavg space. This MPF image is acquired in its own native space, so the two volumes are not aligned by default. By registering the MPF to the rawavg
# and then applying this tranform to map the MPF into aparc+aseg space, we ensure that each MPF voxels corresponds to the correct anatomical label
# when computing parcel-wise MPF statistics. 

# Outputs: 
#	- for each sbuject: a *_mpf_segstats.txt file containing parcel-wise MPF stats. 
	- temporary LTA tranforms and coregistered MPF volumes are stored in TEMP_DIR.

# Usage: extract_mean_mpf.sh

INPUT_DIR="freesurfer_output"
OUTPUT_DIR="avg_MPF_values_in_parcels"
TEMP_DIR="./temp_asegstats_files"
CTAB="$FREESURFER_HOME/FreeSurferColorLUT.txt"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Loop over all mpf directories
for mpf_dir in "$INPUT_DIR"/H??-?_MPFcor_freesurfer; do
	subj_scan=$(basename "$mpf_dir")
	mri_dir="$mpf_dir/mri"
	seg_file="$mri_dir/aparc+aseg.mgz"
	rawavg_file="$mri_dir/rawavg.mgz"
	orig_mpf_file="$mri_dir/orig/001.mgz"

	if [[ -f "$seg_file" && -f "$orig_mpf_file" ]]; then
		echo "Processing $subj_scan"

		output_file="$OUTPUT_DIR/${subj_scan}_mpf_segstats.txt"
		lta_file="${TEMP_DIR}/${subj_scan}_mpf2rawavg.lta"
		coreg_mgz="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg.mgz"	

		# Register original MPF volume with rawavg.mgz
		mri_robust_register --mov "$orig_mpf_file" --dst "$rawavg_file" --lta "$lta_file" --satit --iscale
	
		# Use this transform to register original MPF with aparc+aseg.mgz
		mri_vol2vol --mov "$orig_mpf_file" --targ "$seg_file" --lta "$lta_file" --o "$coreg_mgz" --interp trilinear	

		# Calculate parcel statistics
		mri_segstats --seg "$seg_file" --in "$coreg_mgz" --ctab "$CTAB" --sum "$output_file"

	else
		echo "Skipping $subj_scan (missing aparc+aseg.mgz or 001.mgz)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"
