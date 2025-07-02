#!/bin/bash

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
