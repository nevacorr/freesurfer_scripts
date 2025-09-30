#!/usr/bin/env bash

# Usage: generate_stats_file_mprage.sh

for SUBJDIR in ./*_mprage*_freesurfer; do
	if [ ! -d "$SUBJDIR" ]; then
		echo "No subject folder found, skipping"
		continue
	fi

	SUBJNAME=$(basename "$SUBJDIR")
	MPRAGE_SEG="$SUBJDIR/mri/aparc+aseg.mgz"
	STATS_FILE="aseg_output/${SUBJNAME}_MPRAGE.stats"

	mkdir -p "$SUBJDIR/stats"

	mri_segstats --seg "$MPRAGE_SEG" --sum "$STATS_FILE"

done
