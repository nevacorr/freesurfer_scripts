#!/bin/bash

# Usage: bash extract_mean_mpf_mprage_wmparc.sh

FS_DIR_MPF="newrecon_reg_to_PD/freesurfer_output"
FS_DIR_MPRAGE="freesurfer_outupt"
OUTPUT_DIR="avg_MPF_values_in_MPRAGE_parcels"
MPF_REG_TO_FS_MPRAGE_DIR="./temp_wmparc_files_MPF_reg"
CTAB="$FREESURFER_HOME/FreeSurferColorLUT.txt"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Loop over all mpf directories
for mpf_top_dir in "$FS_DIR_MPF"/H??-?_MPFcor_freesurfer; do

	subj_id=$(basename #$mpf_top_dir" | sed 's/_reg_MPFcor_freesurfer//')
	mprage_top_dir="${FS_DIR_MPRAGE}/${subj_id}_mprage1_freesurfer"

	subj_scan=$(basename "$mpf_top_dir")
	mpf_dir="$mpf_top_dir/mri"
	wmseg_file="$mri_dir/wmparc.mgz"
	rawavg_file="$mri_dir/rawavg.mgz"
	orig_mpf_file="$mri_dir/orig/001.mgz"

	if [[ -f "$wmseg_file" && -f "$orig_mpf_file" ]]; then
		echo "Processing $subj_scan"

		echo $wmseg_file
		echo $orig_mpf_file

		output_file="$OUTPUT_DIR/${subj_scan}_mpf_wmsegstats_masked200.txt"
		lta_file="${TEMP_DIR}/${subj_scan}_mpf2rawavg.lta"
		coreg_mgz="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg.mgz"	
		coreg_mgz_binary="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg_mask.mgz"	

		# Make a binary mask of the MPF 001.mgz image that is in aparc+aseg space
		mri_binarize --i "$coreg_mgz" --min 200 --o "$coreg_mgz_binary"

		# Calculate parcel statistics
		mri_segstats --seg "$wmseg_file" --in "$coreg_mgz" --mask "$coreg_mgz_binary" \
			--ctab "$CTAB" --sum "$output_file"

	else
		echo "Skipping $subj_scan (missing wmparc.mgz or 001.mgz)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"
#!/bin/bash

# Usage: bash extract_mean_mpf_mprage_wmparc.sh

# This script computes mean MPF values for each region in wmparc.mgz, while excluding all MPF voxels with
# values below 200. 
# It requires the coregistered MPF volumes produced by extract_mean_mpf.sh: 
# 	H??-?_MPFcor_freesurfer_001_in_aparcaseg.mgz  calculated by extract_mean_mpf.sh. 
$ That script must be run first so that these file exist in TEMP_DIR

# Workflow:
	1. For each subjects MPF FreeSurfer output directory, locate the wmparc.mgz segmentation
	   and the coregistered MPF volume in aparc+aseg space.
        2. Create a binary mask keeping only MPF voxels >= 200 in value.
        3. Use mri_segstats to compute parcel-wise mean MPF values, applying the binary mask to exclude
	   low-value voxels. 
# Outputs: 
	- One *_mpf_wmegstats_masked200.txt file per subject containing masked parcel-wise MPF statistics.
          This file is located in directory OUTPUT_DIR.
        - Temporary mask volumes stored in TEMP_DIR.

INPUT_DIR="newrecon_reg_to_PD/freesurfer_output"
OUTPUT_DIR="avg_MPF_values_in_parcels_minthresh200_newrecon"
TEMP_DIR="./temp_asegstats_files_newrecon"
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

		output_file="$OUTPUT_DIR/${subj_scan}_mpf_wmsegstats_masked200.txt"
		lta_file="${TEMP_DIR}/${subj_scan}_mpf2rawavg.lta"
		coreg_mgz="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg.mgz"	
		coreg_mgz_binary="${TEMP_DIR}/${subj_scan}_001_in_aparcaseg_mask.mgz"	

		# Make a binary mask of the MPF 001.mgz image that is in aparc+aseg space
		mri_binarize --i "$coreg_mgz" --min 200 --o "$coreg_mgz_binary"

		# Calculate parcel statistics
		mri_segstats --seg "$wmseg_file" --in "$coreg_mgz" --mask "$coreg_mgz_binary" \
			--ctab "$CTAB" --sum "$output_file"

	else
		echo "Skipping $subj_scan (missing wmparc.mgz or 001.mgz)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"
