#!/bin/bash

# Usage: extract_mean_mpf.sh

INPUT_DIR="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output"
MASKS_DIR="combined_masks"
OUTPUT_FILE="avg_MPF_values_in_all_regions.tsv"
TEMP_DIR="./temp_mpf_stats"
REGIONS_LIST="regions.txt"

mkdir -p "$TEMP_DIR"

# Load region names into array
mapfile -t REGION_NAMES < "$REGIONS_LIST"
echo "Regions loaded: ${#REGION_NAMES[@]}"

# Write header row
{
	echo -ne "subject"
	for region in "${REGION_NAMES[@]}"; do
		echo -ne "\t$region"
	done
	echo
} > "$OUTPUT_FILE"

# Loop over each subject directory
for mpf_dir in "$INPUT_DIR"/H??-?_MPFcor_freesurfer; do
	subj=$(basename "$mpf_dir")
	mri_dir="$mpf_dir/mri"
	rawavg_file="$mri_dir/rawavg.mgz"
	orig_mpf_file="$mri_dir/orig/001.mgz"
	lta_file="${TEMP_DIR}/${subj}_mpf2rawavg.lta"

	if [[ ! -f "$rawavg_file" || ! -f "$orig_mpf_file" ]]; then
		echo "Skipping $subj because missing MPF or rawavg file"
		continue
	fi

	# Register original MPF volume with rawavg.mgz
	mri_robust_register --mov "$orig_mpf_file" --dst "$rawavg_file" --lta "$lta_file" --satit --iscale
	
	output_line="$subj"

	for region in "${REGION_NAMES[@]}"; do
		mask="$MASKS_DIR/$subj/${region}.mgz"
		coreg_mgz="${TEMP_DIR}/${subj}_${region}_mpf_in_maskspace.mgz"

		# Tranform MPF to mask space
		mri_vol2vol --mov "$orig_mpf_file" --targ "$mask" --lta "$lta_file" --o "$coreg_mgz" --interp trilinear	

		temp_stats=$(mktemp)
		mri_segstats --seg "$mask" --in "$coreg_mgz" --excludeid 0 --sum "$temp_stats" > /dev/null 2>&1

		# Extract mean MPF
		vol=$(awk '$1 ==1 {print $5}' "$temp_stats")
		rm -f "$temp_stats" "$coreg_mgz"

		if [[ -z "$vol" ]]; then vol="NA"; fi

		output_line+=$'\t'"$vol"
	done

	# Append subject's results to output file
	echo -e "$output_line" >> "$OUTPUT_FILE"	

done

echo "Calculations complete. All results are saved in $OUTPUT_FILE"
