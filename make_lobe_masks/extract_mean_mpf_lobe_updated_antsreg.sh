#!/bin/bash

# Usage: nohup bash extract_mean_mpf_lobe_updated_antsreg.sh > output.log 2>&1 &
#        or bash extract_mean_mpf_lobe_updated_antsreg.sh 2>&1 | tee output.log

# This script computes mean MPF values for each region in wmparc.mgz from 1) the fs parcellation of the MPF (volumes
# generated after registering component images), while excluding all MPF voxels with
# values below 200 and 2) wmparc.mgz from the fs parcellation of the MPRAGE, while excluding all MPF voxels with values below 200
# and 3) the wmparc.mgz from the fs parcellation of the MPF where the component images were not registered prior to MPF reconstruction

source ~/miniconda3/etc/profile.d/conda.sh
conda activate ants
which antRegistration

FS_DIR_MPF="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output"
FS_DIR_MPF_REG="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/freesurfer_output" # directory with new mpf all PD reg fs processed output
FS_DIR_MPRAGE="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output" 	          # directory with mprage fs processed output
MASKS_DIR="combined_masks_Feb2026"
REGIONS_LIST="allregions.txt"

OUTPUT_DIR="avg_MPF_custom_region_values_Feb2026" # directory to write output mean MPF stats file to
TEMP_DIR="./temp_custom_region_files" 		  # directory to write intermediate files to 

mkdir -p "$OUTPUT_DIR" "$TEMP_DIR"

mean_mpf_mpf="$OUTPUT_DIR/allsubjects_mpf_mean_mpfspace.csv"
sd_mpf_mpf="$OUTPUT_DIR/allsubjects_mpf_sd_mpfspace.csv"
mean_mpf_mpf_reg="$OUTPUT_DIR/allsubjects_mpf_mean_mpfregspace.csv"
sd_mpf_mpf_reg="$OUTPUT_DIR/allsubjects_mpf_sd_mpfregspace.csv"
mean_mpf_mprage="$OUTPUT_DIR/allsubjects_mpf_mean_mpragespace.csv"
sd_mpf_mprage="$OUTPUT_DIR/allsubjects_mpf_sd_mpragespace.csv"

#Loop over all subject directories

for space in mpf mpf_reg mprage; do

	if [[ "$space" == "mpf" ]]; then
		fs_dir="$FS_DIR_MPF"
		suffix="_MPFcor_freesurfer"
		mean_output="$mean_mpf_mpf"
		sd_output="$sd_mpf_mpf"

	elif [[ "$space" == "mpf_reg" ]]; then
		fs_dir="$FS_DIR_MPF_REG"
		suffix="_reg_MPFcor_freesurfer"
		mean_output="$mean_mpf_mpf_reg"
		sd_output="$sd_mpf_mpf_reg"

	elif [[ "$space" == "mprage" ]]; then
		fs_dir="$FS_DIR_MPRAGE"
		suffix="_mprage1_freesurfer"
		mean_output="$mean_mpf_mprage"
		sd_output="$sd_mpf_mpf_mprage"
	fi
	
	pattern="$fs_dir/H??-?${suffix}"

	echo "Pattern for $space: $pattern"

	subjects=($fs_dir/H??-?${suffix})

        for subj_dir in ${subjects[@]}; do

		subj_id=$(basename "$subj_dir" | sed "s/${suffix}//")

		subject_top_dir="${fs_dir}/${subj_id}${suffix}"
		mri_dir="$subject_top_dir/mri"
		wmseg_file="$mri_dir/wmparc.mgz"      	# full path to wmparc.mgz seg file from fs output
		brain_fs_file="$mri_dir/brain.mgz"     	# full path to brain.mgz file from fs output
		orig_mpf_file="$FS_DIR_MPF_REG/${subj_id}_reg_MPFcor_freesurfer/mri/orig/001.mgz"   # path to MPF reg file

		echo ""
		echo "---------------------"
		echo "Processing $subj_id in $space space"

		if [[ -f "$wmseg_file" ]]; then
			echo " ---------> Registering to ${space} space"

			prefix="${TEMP_DIR}/${subj_id}_${space}"

			coreg_nii="${prefix}_001_in_wmparc.nii.gz"             # location of 001 in wmparc space	
			coreg_nii_binary="${prefix}_001_in_wmparc_mask.nii.gz" # location of mask where 001 in wmparc space has values >200	
			coreg_mgz="${prefix}_001_in_wmparc.mgz"                # location of 001 in wmparc space	
			coreg_mgz_binary="${prefix}_001_in_wmparc_mask.mgz"    # location of mask where 001 in wmparc space has values >200	

			if [[ ! -f "$coreg_mgz_binary" ]]; then

				# Create prefix for ANTS registration output
				ants_prefix="${prefix}_ants"

				mpf_nii="${prefix}_001_for_wmparc_coreg.nii.gz"
				brain_nii="${prefix}_brain.nii.gz"

				echo "Convert input images from MGZ to NIFTI"
				mri_convert "$orig_mpf_file" "$mpf_nii"
				mri_convert "$brain_fs_file" "$brain_nii"

				# Perform rigid registration of mpf file to mri brain.mgz			
				antsRegistration -d 3 \
					-r "[$brain_nii,$mpf_nii,1]" \
					-m "MI[$brain_nii,$mpf_nii,1,32]"  \
					-t "Rigid[0.1]"  \
					-c "[1000x500x250,1e-6,10]" \
					-s "4x2x1vox" \
					-f "8x4x2" \
					-o "${ants_prefix}_Rigid_"

				# Perform affine registration of mpf file to mri brain.mgz
				antsRegistration -d 3 \
					-r "[${ants_prefix}_Rigid_0GenericAffine.mat,1]"  \
					-m "MI[$brain_nii,$mpf_nii,1,32]" \
					-t "Affine[0.1]" \
					-c "[1000x500x250,1e-6,10]" \
					-s "4x2x1vox" \
					-f "8x4x2" \
					-o "${ants_prefix}_Affine_"

				# Apply final transform to original mpf to bring it into brain.mgz / wmparc space
				antsApplyTransforms -d 3 \
					-i "$mpf_nii" \
					-r "$brain_nii" \
					-o "$coreg_nii" \
					-t "${ants_prefix}_Affine_0GenericAffine.mat" \
					-n Linear

				echo "Check transformed output file"
				ls -lh "$coreg_nii"

				# Make a binary mask of the MPF 001.mgz image that is in wmparc space
				mri_binarize --i "$coreg_nii" --min 200 --o "$coreg_nii_binary"  

				mri_convert "$coreg_nii" "$coreg_mgz"
				mri_convert "$coreg_nii_binary" "$coreg_mgz_binary"

			else 
				echo " -_-------> Registration and masking for MPF already done, skipping"
			fi


			# Extract headers and values
			if [[ ! -f "$mean_output" ]]; then
				headers=$(awk '{printf ",%s", $1} END {print ""}' "$REGIONS_LIST")
				echo "Subject$headers" > "$mean_output"
				echo "Subject$headers" > "$sd_output"
			fi

			mean_vals=""
			sd_vals=""

			# Calculate mean MPF value in each region
			while read -r region; do 
				region_mask="$MASKS_DIR/$subj_id${suffix}/${region}.mgz"

				if [[ ! -f "$region_mask" ]]; then
					mean_vals+=",NA"
					sd_vals+=",NA"
					continue
				fi
			

				tmp_mask="${prefix}_${region}_mask.mgz"
				mri_and "$region_mask" "$coreg_mgz_binary" "$tmp_mask"

				stats=$(mri_stats --mask "$tmp_mask" --i "$coreg_mgz" --mean --std 2>/dev/null)

				mean=$(echo "$stats" | awk '{print $1}')
				sd=$(echo "$stats" | awk '{print $2}')

				mean_vals+=",$mean"
				sd_vals+=",$sd"
		
			done < "$REGIONS_LIST"	
	
			echo "$subj_id$mean_vals" >>"$mean_output"
			echo "$subj_id$sd_vals" >> "$sd_output"
		fi
	done
done

echo "Calculations complete. All results are saved in $OUTPUT_DIR"


