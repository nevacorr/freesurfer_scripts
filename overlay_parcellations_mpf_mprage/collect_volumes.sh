#!/usr/bin/env bash

# Usage: ./collect_volumes.sh <folder_with_stats_files>  region_volumes.csv

STATS_FOLDER=$1
OUTFILE=$2

# Write CSV header
echo "Subject,CorticalGM_mm3,CerebralWM_mm3,Subcortical_GM_mm3,CSF_mm3" > "$OUTFILE"

for STATS in "$STATS_FOLDER"/*.stats; do
	if [ ! -f "$STATS" ]; then
		echo "No stats files found in $STATS_FOLDER, skipping."
		continue
	fi
	
	# Cortical GM (left and right cerebral cortex)
	cortical_gm=$(awk '$5 ~ /^ctx-/ {sum+=$4} END {print sum+0}' "$STATS")

	# Cerebral WM (hemispheric WM + callosum )
	cerebral_wm=$(awk '($5=="Left-Cerebral-White-Matter" || $5=="Right-Cerebral-White-Matter" || $5 ~ /^CC_/) {sum+=$4} END {print sum+0}' "$STATS")
	
	# Subcortical GM (thalamus, caudate, putamen, pallidum, hippocampus, amygdala, accumbens)
	subcortical_gm=$(awk '$5 ~ /Thalamus|Caudate|Putamen|Pallidum|Hippocampus|Amygdala|Accumbens/ {sum+=$4} END {print sum+0}' "$STATS")
	
	# CSF (ventricles and CSF label)
	csf=$(awk '$5 ~ /CSF|Lateral-Ventricle|Inf-Lat-Vent|3rd-Ventricle/ {sum+=$4} END {print sum+0}' "$STATS")

	subjname=$(basename "$STATS" .stats)

	# Append to CSV
	echo "$subjname,$cortical_gm,$cerebral_wm,$subcortical_gm,$csf" >> "$OUTFILE"

done 

