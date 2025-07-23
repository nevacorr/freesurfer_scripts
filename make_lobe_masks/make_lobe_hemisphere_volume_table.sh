#!/bin/bash

# Note that this file will calculate volumes based on summing of masks. However, it will yield different values than 
# those produced by aparcstats2table and asegstats2table because those functions take into account partial volume effects
# or corrections. There may also be small gaps or extra voxels at the border that are not included in those functions.
# For subcortical regions, I find that the difference between my program here and the output of asegstats2table is about 2.5%.
# I prefer to sum the values to those tables than use the values calculated here.

SUBJECTS_DIR="/home/toddr/neva/MPF/make_lobe_masks/combined_masks"
SUBJECTS_LIST="subjects_list.txt"
REGIONS_LIST="regions.txt"
OUTPUT="lobe_and_hemi_volumes_table.tsv"

mapfile -t REGION_NAMES < "$REGIONS_LIST"

echo "Loaded ${#REGION_NAMES[@]} regions from $REGIONS_LIST"
printf '%s\n' "${REGION_NAMES[@]}"

# Write header to output file
{
	echo -ne "subject"
	for region in "${REGION_NAMES[@]}"; do
		echo -ne "\t$region"
	done
	echo
} > "$OUTPUT"

# Loop over subjects
while IFS= read -r subj || [[ -n "$subj" ]]; do
	echo subj ${subj}
	subj_path="$SUBJECTS_DIR/$subj"
	echo subj_path ${subj_path}

	output_line="$subj"

	for region in "${REGION_NAMES[@]}"; do
		echo region ${region}
		mask="$subj_path/$region.mgz"
		if [[ -f "$mask" ]]; then
			temp_stats=$(mktemp)
			mri_segstats --seg "$mask" --excludeid 0 --sum "$temp_stats" >/dev/null 2>&1
			vol=$(awk '$1 == 1 {print $4}' "$temp_stats")
			rm -f "$temp_stats"
		else
			vol="NA"
		fi
		output_line+="\t$vol"	
	done

	echo  -e "$output_line" >> "$OUTPUT"

done < "$SUBJECTS_LIST" 
