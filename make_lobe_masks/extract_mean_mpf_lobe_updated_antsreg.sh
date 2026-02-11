#!/bin/bash

# Make sure to run conda activate ants prior to running
# Usage: nohup bash extract_mean_mpf_lobe_updated_antsreg.sh > output.log 2>&1 &

# This script computes mean MPF values for each region in wmparc.mgz from 1) the fs parcellation of the MPF (volumes
# generated after registering component images), while excluding all MPF voxels with
# values below 200 and 2) wmparc.mgz from the fs parcellation of the MPRAGE, while excluding all MPF voxels with values below 200

#set -e #stop on errors

FS_DIR_MPF="newrecon_reg_to_PD/freesurfer_output" # directory with new mpf all PD reg fs processed output
FS_DIR_MPRAGE="freesurfer_output" 	          # directory with mprage fs processed output
MASKS_DIR="combined_masks_Feb2026"
REGIONS_LIST="allregions.txt"

OUTPUT_DIR="avg_MPF_custom_region_values_Feb2026" # directory to write output mean MPF stats file to
TEMP_DIR="./temp_custom_region_files" 		  # directory to write intermediate files to 

mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

mean_mpf_mpfreg="$OUTPUT_DIR/allsubjects_mpf_mean_mpfregspace.csv"
sd_mpf_mpfreg="$OUTPUT_DIR/allsubjects_mpf_sd_mpfregspace.csv"
mean_mpf_mprage="$OUTPUT_DIR/allsubjects_mpf_mean_mpragespace.csv"
sd_mpf_mprage="$OUTPUT_DIR/allsubjects_mpf_sd_mpragespace.csv"

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


		# Extract headers and values
		if ! $header_written_mpf; then
			headers=$(awk '{printf ",%s", $1} END {print ""}' "$REGIONS_LIST")
			echo "Subject$headers" > "$mean_mpf_mpfreg"
			echo "Subject$headers" > "$sd_mpf_mpfreg"
			header_written_mpf=true
		fi

		mean_vals=""
		std_vals=""

		# Calculate mean MPF value in each region
		while read -r region; do 
			region_mask="$MASKS_DIR/$subj_id/${region}.mgz"

			if [[ ! -f "$region_mask" ]]; then
				mean_val+=",NA"
				sd_vals+=",NA"
				continue
			fi
			

			tmp_mask="$TEMP_DIR/${subj_id}_${region}_mpfmask.mgz"
			mri_and "$region_mask" "$coreg_mgz_binary_mpf" "$tmp_mask"

			stats=$(mri_stats --mask "$tmp_mask" --i "$coreg_mgz_mpf" --mean --std 2>/dev/null)

			mean=$(echo "$stats" | awk '{print $1}')
			sd=$(echo "$stats" | awk '{print $2}')

			mean_vals+=",$mean"
			sd_vals+=",$sd"
		
		done < "$REGIONS_LIST"	
	
		echo "$subj_id$mean_vals" >>"$mean_mpf_mpfreg"
		echo "$subj_id$std_vals" >> "$sd_mpf_mpfreg"

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

		# Extract headers and values
		if ! $header_written_mprage; then
			headers=$(awk '{printf ",%s", $1} END {print "")' "$REGIONS_LIST") 
			echo "Subject$headers" > "$mean_mpf_mprage"
			echo "Subject$headers" > "$sd_mpf_mprage"
			header_written_mprage=true
		fi

		mean_vals=""
		sd_vals=""

		while read -r region; do
			region_mask="$MASKS_DIR/$subj_id/${region}.mgz"

			if [[ ! -f "$region_mask" ]]; then
				mean_vals+=",NA"
				sed_vals+=",NA"
				continue
			fi

			tmp_mask="$TEMP_DIR/${subj_id}_${region}_mpragemask.mgz"
			mri_and "$region_mask" "$coreg_mgz_binary_mprage" "$tmp_mask"

			# Calculate mean MPF value using MPRAGE parcellation
			stats=$(mri_stats --mask "$tmp_mask" --i "$coreg_mgz_mprage" --mean --std 2>/dev/null)

			mean=$(echo "$stats" | awk '{print $1}')
			sd=$(echo "$stats" | awk '{print $2)')

			mean_vals+=",$mean"
			sd_vals+=",$sd"

		done < "$REGIONS_LIST"
		
		echo "$subj_id$mean_vals" >>"$mean_mpf_mprage"
		echo "$subj_id$sd_vals" >> "$sd_mpf_mprage"


	else
		echo "Skipping $subj_id calculation for MPRAGE parcellation (missing wmparc.mgz for MPRAGE)"

	fi
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"


