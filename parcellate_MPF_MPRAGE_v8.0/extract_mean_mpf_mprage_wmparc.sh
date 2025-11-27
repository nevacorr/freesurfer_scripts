#!/bin/bash

# Make sure to run conda activate ants prior to running
# Usage: nohup bash extract_mean_mpf_mprage_wmparc.sh > output.log 2>&1 &

# This script computes mean MPF values for each region in 1. wmparc.mgz from the fs parcellation of the MPF, while excluding all MPF voxels with
# values below 200 and 2) wmparc.mgz from the fs parcellation of the MPRAGE, while excluding all MPF voxels with values below 200

#set -e #stop on errors

FS_DIR_MPF="newrecon_reg_to_PD/freesurfer_output" # directory with new mpf all PD reg fs processed output
FS_DIR_MPRAGE="freesurfer_output" 	          # directory with mprage fs processed output
OUTPUT_DIR="avg_MPF_reg_values"	  		  # directory to write output mean MPF stats file to
TEMP_DIR="./temp_wmparc_files_MPF_reg" 		  # directory to write intermediate files to 
CTAB="$FREESURFER_HOME/FreeSurferColorLUT.txt"    # file with region names used by mrisegstats

mean_mpf_mpfparc="$OUTPUT_DIR/allsubjects_mpf_mean_mpfparc.csv"   #  name and path of output mean MPF file for MPF parcellation
sd_mpf_mpfparc="$OUTPUT_DIR/allsubjects_mpf_stdev_mpfparc.csv"   #  name and path of output std MPF file for MPF parcellation
mean_mpf_mprageparc="$OUTPUT_DIR/allsubjects_mpf_mean_mprageparc.csv"   #  name and path of output mean MPF file for MPRAGE parcellation
sd_mpf_mprageparc="$OUTPUT_DIR/allsubjects_mpf_stdev_mprageparc.csv"   #  name and path of output std MPF file for MPRAGE parcellation

mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Flags to write headers only once
header_written_mpf=false
header_written_mprage=false

# Loop over all mpf directories
for mpf_top_dir in "$FS_DIR_MPF"/H??-?_reg_MPFcor_freesurfer; do    # for every directory with MPF reg data

	subj_id=$(basename "$mpf_top_dir" | sed 's/_reg_MPFcor_freesurfer//')  # extract subject ID
	mprage_top_dir="${FS_DIR_MPRAGE}/${subj_id}_mprage1_freesurfer"        # find MPRAGE fs processed output for this subject

	mpf_dir="$mpf_top_dir/mri"            		# path to mri directory in subject's MPF fs output
	mprage_dir="$mprage_top_dir/mri"      		# path to mri directory in subject's MPRAGE fs output
	wmseg_file_mpf="$mpf_dir/wmparc.mgz"      	# full path to wmparc.mgz seg file from MPF fs output
	wmseg_file_mprage="$mprage_dir/wmparc.mgz"     	# full path to wmparc.mgz seg file from MPRAGE fs output
	brain_fs_file_mpf="$mpf_dir/brain.mgz"     	# full path to brain.mgz file from MPF fs output
	brain_fs_file_mprage="$mprage_dir/brain.mgz"   	# full path to brain.mgz file from MPRAGE fs output
	orig_mpf_file="$mpf_dir/orig/001.mgz" 		# full path to 001.mgz file from MPF fs output

	echo ""
	echo "---------------------"
	echo "Processing $subj_id"

	# Use MPF parcellation
	if [[ -f "$wmseg_file_mpf" ]]; then
		echo " ---------> Registering to MPF space"

		coreg_nii_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc.nii.gz"             # location of MPF 001 in MPF wmparc space	
		coreg_nii_binary_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc_mask.nii.gz" # location of mask where MPF 001 in mpf wmparc space has values >200	
		coreg_mgz_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc.mgz"          	    # location of MPF 001 in MPF wmparc space	
		coreg_mgz_binary_mpf="${TEMP_DIR}/${subj_id}_001_in_mpf_wmparc_mask.mgz"    # location of mask where MPF 001 in mpf wmparc space has values >200	

		if [[ ! -f "$coreg_mgz_binary_mpf" ]]; then

			# Create prefix for ANTS registration output
			ants_prefix="${TEMP_DIR}/${subj_id}_mpf2mpf"

			mpf_nii="${TEMP_DIR}/${subj_id}_001_for_mpf_wmparc_coreg.nii.gz"
			brain_mpf_nii="${TEMP_DIR}/${subj_id}_brain_mpf.nii.gz"

			echo "Convert input images from MGZ to NIFTI"
			mri_convert "$orig_mpf_file" "$mpf_nii"
			mri_convert "$brain_fs_file_mpf" "$brain_mpf_nii"

			# Perform rigid registration of mpf file  to mpf brain.mgz			
			antsRegistration -d 3 \
				-r "[$brain_mpf_nii,$mpf_nii,1]" \
				-m "MI[$brain_mpf_nii,$mpf_nii,1,32]"  \
				-t "Rigid[0.1]"  \
				-c "[1000x500x250,1e-6,10]" \
				-s "4x2x1vox" \
				-f "8x4x2" \
				-o "${ants_prefix}_Rigid_"

			# Perform affine registration of mpf file to mpf brain.mgz
			antsRegistration -d 3 \
				-r "[${ants_prefix}_Rigid_0GenericAffine.mat,1]"  \
				-m "MI[$brain_mpf_nii,$mpf_nii,1,32]" \
				-t "Affine[0.1]" \
				-c "[1000x500x250,1e-6,10]" \
				-s "4x2x1vox" \
				-f "8x4x2" \
				-o "${ants_prefix}_Affine_"

			# Apply final transform to original MPF to bring it into brain.mgz / wmparc space
			antsApplyTransforms -d 3 \
				-i "$mpf_nii" \
				-r "$brain_mpf_nii" \
				-o "$coreg_nii_mpf" \
				-t "${ants_prefix}_Affine_0GenericAffine.mat" \
				-n Linear

			echo "Check transformed output file"
			ls -lh "$coreg_nii_mpf"

			# Make a binary mask of the MPF 001.mgz image that is in MPF wmparc space
			mri_binarize --i "$coreg_nii_mpf" --min 200 --o "$coreg_nii_binary_mpf"  

			mri_convert "$coreg_nii_mpf" "$coreg_mgz_mpf"
			mri_convert "$coreg_nii_binary_mpf" "$coreg_mgz_binary_mpf"

		else 
			echo " -_-------> Registration and masking for MPF already done, skipping"
		fi

		# Calculate mean MPF value in each gm and wm parcel using MPF parcellation
		mri_segstats --seg "$wmseg_file_mpf" --in "$coreg_mgz_mpf" --mask "$coreg_mgz_binary_mpf" --ctab "$CTAB" --sum tmp_mpf.txt


		# Extract headers and values
		if ! $header_written_mpf; then
			headers=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%s", $5}' tmp_mpf.txt)
			echo "Subject$headers" > "$mean_mpf_mpfparc"
			echo "Subject$headers" > "$sd_mpf_mpfparc"
			header_written_mpf=true
		fi

		mean_vals=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%.4f",$6}' tmp_mpf.txt)
		std_vals=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%.4f",$7}' tmp_mpf.txt)

		echo "$subj_id$mean_vals" >>"$mean_mpf_mpfparc"
		echo "$subj_id$std_vals" >> "$sd_mpf_mpfparc"

	else
		echo "Skipping $subj_id for MPF parcellation (missing wmparc.mgz for MPF)"
	fi
		
	# Use MPRAGE parcellation
	if [[ -f "$wmseg_file_mprage" ]]; then
		echo " ---------> Registering to MPRAGE space"

		coreg_nii_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc.nii.gz"    	# location of MPF 001 in MPRAGE wmparc space	
		coreg_nii_binary_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc_mask.nii.gz" # location of mask where MPF 001 in mprage wmparc space has values >200	
		coreg_mgz_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc.mgz"    		# location of MPF 001 in MPRAGE wmparc space	
		coreg_mgz_binary_mprage="${TEMP_DIR}/${subj_id}_001_in_mprage_wmparc_mask.mgz"  # location of mask where MPF 001 in mprage wmparc space has values >200	
		
		if [[ ! -f "$coreg_mgz_binary_mprage" ]]; then

			# Create prefix for ANTS registration output
			ants_prefix="${TEMP_DIR}/${subj_id}_mpf2mprage"

			mpf_nii="${TEMP_DIR}/${subj_id}_001_for_mprage_wmparc_coreg.nii.gz"
			brain_mprage_nii="${TEMP_DIR}/${subj_id}_brain_mprage.nii.gz"

			echo "Convert input images from MGZ to NIFTI"
			mri_convert "$orig_mpf_file" "$mpf_nii"
			mri_convert "$brain_fs_file_mprage" "$brain_mprage_nii"

			# Perform rigid registration of mpf file  to mprage brain.mgz			
			antsRegistration -d 3 \
				-r "[$brain_mprage_nii,$mpf_nii,1]" \
				-m "MI[$brain_mprage_nii,$mpf_nii,1,32]"  \
				-t "Rigid[0.1]"  \
				-c "[1000x500x250,1e-6,10]" \
				-s "4x2x1vox" \
				-f "8x4x2" \
				-o "${ants_prefix}_Rigid_"

			# Perform affine registration of mpf file to mprage brain.mgz
			antsRegistration -d 3 \
				-r "[${ants_prefix}_Rigid_0GenericAffine.mat,1]"  \
				-m "MI[$brain_mprage_nii,$mpf_nii,1,32]" \
				-t "Affine[0.1]" \
				-c "[1000x500x250,1e-6,10]" \
				-s "4x2x1vox" \
				-f "8x4x2" \
				-o "${ants_prefix}_Affine_"

			# Apply final transform to original MPF to bring it into brain.mgz / wmparc space
			antsApplyTransforms -d 3 \
				-i "$mpf_nii" \
				-r "$brain_mprage_nii" \
				-o "$coreg_nii_mprage" \
				-t "${ants_prefix}_Affine_0GenericAffine.mat" \
				-n Linear

			# Make a binary mask of the MPF values > 200 
			mri_binarize --i "$coreg_nii_mprage" --min 200 --o "$coreg_nii_binary_mprage" 

			mri_convert "$coreg_nii_mprage" "$coreg_mgz_mprage"
			mri_convert "$coreg_nii_binary_mprage" "$coreg_mgz_binary_mprage"

		else 
			echo " --------> Registration and masking for MPRAGE already done, skipping"
		fi

		# Calculate mean MPF value in each gm and wm parcel using MPRAGE parcellation
		mri_segstats --seg "$wmseg_file_mprage" --in "$coreg_mgz_mprage" --mask "$coreg_mgz_binary_mprage" --ctab "$CTAB" --sum tmp_mprage.txt
		
		# Extract headers and values
		if ! $header_written_mprage; then
			headers=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%s", $5}' tmp_mprage.txt)
			echo "Subject$headers" > "$mean_mpf_mprageparc"
			echo "Subject$headers" > "$sd_mpf_mprageparc"
			header_written_mprage=true
		fi

		mean_vals=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%.4f",$6}' tmp_mprage.txt)
		std_vals=$(awk 'NR>1 && $0 !~ /^#/ {printf ",%.4f",$7}' tmp_mprage.txt)

		echo "$subj_id$mean_vals" >>"$mean_mpf_mprageparc"
		echo "$subj_id$std_vals" >> "$sd_mpf_mprageparc"


	else
		echo "Skipping $subj_id calculation for MPRAGE parcellation (missing wmparc.mgz for MPRAGE)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"


