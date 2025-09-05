#!/bin/bash

# This program registers MPF imaages to mprage

# Usage: bash register_parcellations.sh <mpf_dir> <mprage_dir>
# Example: bash register_parcellations.sh H05-2_MPFcor_freesurfer H05-2_mprage1_freesurfer

if [ $# -ne 2 ]; then
	echo "Usage: $0 <mpf_dir> <mprage_dir>"
	exit 1
fi

MPF_DIR=$1
MPRAGE_DIR=$2
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

# Strip "_freesurfer" suffix if present to use in filenames
BASE_NAME=$(basename "$MPF_DIR" _freesurfer)

# Register MPF brain to mprage brain. Create a registration transform
mri_robust_register \
	  --mov "${MPF_DIR}/mri/brain.mgz" \
	  --dst "${MPRAGE_DIR}/mri/brain.mgz" \
	  --lta "${OUTPUT_DIR}/${BASE_NAME}_to_mprage.lta" \
          --satit \
	  --mapmov "${OUTPUT_DIR}/brain_${BASE_NAME}_in_mprage.mgz"

# Resample MPF aparc+aseg into mprage space using transform
mri_vol2vol  \
	   --mov "${MPF_DIR}/mri/aparc+aseg.mgz" \
	    --targ "${MPRAGE_DIR}/mri/aparc+aseg.mgz" \
            --lta "${OUTPUT_DIR}/${BASE_NAME}_to_mprage.lta" \
            --o "${OUTPUT_DIR}/${BASE_NAME}_aparc+aseg_reg_to_mprage.mgz"  --nearest  

