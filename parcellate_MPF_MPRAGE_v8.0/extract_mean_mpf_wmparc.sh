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
	wmseg_file="$mri_dir/wmparc.mgz"
	rawavg_file="$mri_dir/rawavg.mgz"
	orig_mpf_file="$mri_dir/orig/001.mgz"

	if [[ -f "$wmseg_file" && -f "$orig_mpf_file" ]]; then
		echo "Processing $subj_scan"

		echo $wmseg_file
		echo $orig_mpf_file

		output_file="$OUTPUT_DIR/${subj_scan}_mpf_wmsegstats.txt"
		lta_file="${TEMP_DIR}/${subj_scan}_mpf2rawavg.lta"
		coreg_mgz="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg.mgz"	

		# Calculate parcel statistics
		mri_segstats --seg "$wmseg_file" --in "$coreg_mgz" --ctab "$CTAB" --sum "$output_file"

	else
		echo "Skipping $subj_scan (missing wmparc.mgz or 001.mgz)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"
