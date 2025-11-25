#!/bin/bash

# Usage: bash extract_mean_mpf_mprage_wmparc.sh

# This script computes mean MPF values for each region in 1. wmparc.mgz from the fs parcellation of the MPF, while excluding all MPF voxels with
# values below 200 and 2) wmparc.mgz from the fs parcellation of the MPRAGE, while excluding all MPF voxels with values below 200

set -e #stop on errors

FS_DIR_MPF="newrecon_reg_to_PD/freesurfer_output" # directory with new mpf all PD reg fs processed output
FS_DIR_MPRAGE="freesurfer_output" 	          # directory with mprage fs processed output
OUTPUT_DIR="avg_MPF_reg_values"	  		  # directory to write output mean MPF stats file to
TEMP_DIR="./temp_wmparc_files_MPF_reg" 		  # directory to write intermediate files to 
CTAB="$FREESURFER_HOME/FreeSurferColorLUT.txt"    # file with region names used by mrisegstats
output_file_mpf="$OUTPUT_DIR/allsubjects_mpf_wmsegstats_masked200.txt"   #  name and path of output stats file for MPF parcellation
output_file_mprage="$OUTPUT_DIR/allsubjects_mprage_wmsegstats_masked200.txt"   #  name and path of output stats file for MPRAGE parcellation

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"
echo "" > "$output_file_mpf" #create output file for MPF parcellation
echo "" > "$output_file_mprage" #create output file for MPRAGE parcellation

# Loop over all mpf directories
for mpf_top_dir in "$FS_DIR_MPF"/H??-?_reg_MPFcor_freesurfer; do    # for every directory with MPF reg data

	subj_id=$(basename "$mpf_top_dir" | sed 's/_reg_MPFcor_freesurfer//')  # extract subject ID
	mprage_top_dir="${FS_DIR_MPRAGE}/${subj_id}_mprage1_freesurfer"        # find MPRAGE fs processed output for this subject

	mpf_dir="$mpf_top_dir/mri"            		# path to mri directory in subject's MPF fs output
	mprage_dir="$mprage_top_dir/mri"      		# path to mri directory in subject's MPRAGE fs output
	wmseg_file_mpf="$mpf_dir/wmparc.mgz"      	# full path to wmparc.mgz seg file from MPF fs output
	wmseg_file_mprage="$mprage_dir/wmparc.mgz"     	# full path to wmparc.mgz seg file from MPRAGE fs output
	rawavg_file_mpf="$mpf_dir/rawavg.mgz"     	# full path to rawavg.mgz file from MPF fs output
	rawavg_file_mprage="$mprage_dir/rawavg.mgz"    	# full path to rawavg.mgz file from MPRAGE fs output
	orig_mpf_file="$mpf_dir/orig/001.mgz" 		# full path to 001.mgz file from MPF fs output

	echo ""
	echo "---------------------"
	echo "Processing $subj_id"

	# Use MPF parcellation
	if [[ -f "$wmseg_file_mpf" ]]; then
		echo " ---------> Registering to MPF space"

		lta_file_mpf="${TEMP_DIR}/${subj_id}_mpf2mpf_rawavg.lta"	      # location of transform of mpf 001 to rawavg for MPF
		coreg_mgz_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc.mgz"          # location of MPF 001 in MPF wmparc space	
		coreg_mgz_binary_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc_mask.mgz" # location of mask where MPF 001 in mpf wmparc space has values >200	

		if [[ ! -f "$coreg_mgz_binary_mpf" ]]; then

			# Register original MPF volume with rawavg.mgz for MPF
			mri_robust_register --mov "$orig_mpf_file" --dst "$rawavg_file_mpf" --lta "$lta_file_mpf" --satit --iscale

			# Use this transform to register original MPF with MPF wmparc.mgz
			mri_vol2vol --mov "$orig_mpf_file" --targ "$wmseg_file_mpf" --lta "$lta_file_mpf" --o "$coreg_mgz_mpf" --interp trilinear
		
			# Make a binary mask of the MPF 001.mgz image that is in MPF wmparc space
			mri_binarize --i "$coreg_mgz_mpf" --min 200 --o "$coreg_mgz_binary_mpf"  

		else 
			echo " -_-------> Registration and masking for MPF already done, skipping"
		fi

		# Calculate mean MPF value in each gm and wm parcel using MPF parcellation
		mri_segstats --seg "$wmseg_file_mpf" --in "$coreg_mgz_mpf" --mask "$coreg_mgz_binary_mpf" --ctab "$CTAB" --sum tmp_mpf.txt
		
		# Append results to file with all subject data
		echo "Subject $subj_id" >> "$output_file_mpf"
		cat tmp_mpf.txt >> "$output_file_mpf"

	else
		echo "Skipping $subj_id for MPF parcellation (missing wmparc.mgz for MPF)"
	fi
		
	# Use MPRAGE parcellation
	if [[ -f "$wmseg_file_mprage" ]]; then
		echo " ---------> Registering to MPRAGE space"

		lta_file_mprage="${TEMP_DIR}/${subj_id}_mpf2mprage_rawavg.lta"        # location of transform of mpf 001 to rawavg for MPF
		coreg_mgz_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc.mgz"    # location of MPF 001 in MPRAGE wmparc space	
		coreg_mgz_binary_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc_mask.mgz" # location of mask where MPF 001 in mprage wmparc space has values >200	

		if [[ ! -f "$coreg_mgz_binary_mprage" ]]; then

			# Register original MPF volume with rawavg.mgz for MPRAGE
			mri_robust_register --mov "$orig_mpf_file" --dst "$rawavg_file_mprage" --lta "$lta_file_mprage" --satit --iscale

			# Use this transform to register original MPF with MPRAGE wmparc.mgz
			mri_vol2vol --mov "$orig_mpf_file" --targ "$wmseg_file_mprage" --lta "$lta_file_mprage" --o "$coreg_mgz_mprage" --interp trilinear

			# Make a binary mask of the MPF 001.mgz image that is in MPRAGE wmparc space
			mri_binarize --i "$coreg_mgz_mprage" --min 200 --o "$coreg_mgz_binary_mprage" 

		else 
			echo " --------> Registration and masking for MPRAGE already done, skipping"
		fi

		# Calculate mean MPF value in each gm and wm parcel using MPRAGE parcellation
		mri_segstats --seg "$wmseg_file_mprage" --in "$coreg_mgz_mprage" --mask "$coreg_mgz_binary_mprage" --ctab "$CTAB" --sum tmp_mprage.txt
		
		# Append results to file with all subject data
		echo "Subject $subj_id" >> "$output_file_mprage"
		cat tmp_mprage.txt >> "$output_file_mprage"

	else
		echo "Skipping $subj_id calculation for MPRAGE parcellation (missing wmparc.mgz for MPRAGE)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"


