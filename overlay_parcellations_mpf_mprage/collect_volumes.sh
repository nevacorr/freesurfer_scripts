#!/usr/bin/env bash

# Usage: ./collect_volumes.sh <folder_with_stats_files>  region_volumes.csv

STATS_FOLDER=$1
OUTFILE=$2

# Write CSV header
echo "Subject,CorticalGM_mm3,CerebralWM_mm3,WMHypointensities_mm3,Subcortical_GM_mm3,CSF_mm3" > "$OUTFILE"

for STATS in "$STATS_FOLDER"/*_MPF_in_MPRAGE.stats; do
	if [ ! -f "$STATS" ]; then
		echo "No stats files found in $STATS_FOLDER, skipping."
		continue
	fi
	
	# Cortical GM (left and right cerebral cortex)
	cortical_gm=$(grep -E "Left-Cerebral-Cortex|Right-Cerebral-Cortex" "$STATS" \
		| awk -F, '{sum+=$4} END {print sum+0}')

	# WM Hypointensities (separate column)
	wm_hypo=$(grep -E "WM-hypointensities" "$STATS" \
		| awk -F, '{sum+=$4} END {print sum+0}')

	# Cerebral WM (hemispheric WM + callosum + WM hypointensities)
	cerebral_wm=$(grep -E "Left-Cerebral-White-Matter|Right-Cerebral-White-Matter|CC_|WM-hypointensities" "$STATS" \
		| awk -F, '{sum+=$4} END {print sum+0}')
	
	# Subcortical GM (thalamus, caudate, putamen, pallidum, hippocampus, amygdala, accumbens)
	subcortical_gm=$(grep -E "Thalamus|Caudate|Putamen|Pallidum|Hippocampus|Amygdala|Accumbens-area" "$STATS" \
		| awk -F, '{sum+=$4} END {print sum+0}')
	
	# CSF (ventricles and CSF label)
	csf=$(grep -E "CSF|Lateral-Ventricle|Inf-Lat-Vent|3rd-Ventricle" "$STATS" \
		| awk -F, '{sum+=$4} END {print sum+0}')

	subjname=$(basename "$STATS" _MPF_in_MPRAGE.stats)

	# Append to CSV
	echo "$subjname,$cortical_gm,$cerebral_wm,$wm_hypo,$subcortical_gm,$csf" >> "$OUTFILE"

done 
