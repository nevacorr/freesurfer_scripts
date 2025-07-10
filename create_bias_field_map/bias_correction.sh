#!/bin/bash

# Usage:
# ./bias_correction.sh input_image (without extension)

set -e

INPUT_BASENAME=$1 # Full path without extension (include image name without .hdr or .img)
OUTPUT_DIR="bias_outputs"
BRAIN_MASK_NAME="bbVFA1"

if [ -z "$INPUT_BASENAME" ]; then
	echo "Usage $0 /full/path/to/input_image_basename (without .hdr/.img)"
	exit 1
fi

echo "Input basename: $INPUT_BASENAME"
echo "Output directory: $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

# Convert image for Analyze format to NIFTI

# Extract input filename and path
INPUT_DIR=$(dirname "$INPUT_BASENAME")
FILENAME=$(basename "$INPUT_BASENAME")

echo "Converting input mask format Analyze to Nifti..."
fslchfiletype NIFTI "${INPUT_DIR}/${BRAIN_MASK_NAME}.img" "${OUTPUT_DIR}/${BRAIN_MASK_NAME}.nii.gz"
gzip -f "${OUTPUT_DIR}/${BRAIN_MASK_NAME}.nii"

echo "Binarizing brain mask"
fslmaths "${OUTPUT_DIR}/${BRAIN_MASK_NAME}.nii.gz" -bin "${OUTPUT_DIR}/${BRAIN_MASK_NAME}_binary.nii.gz"

echo "Converting input image format Analyze to Nifti..."
fslchfiletype NIFTI "${INPUT_BASENAME}.img" "${OUTPUT_DIR}/${FILENAME}"
gzip -f "${OUTPUT_DIR}/${FILENAME}.nii"

# Run N4 bias field correction
echo "Running N4 Bias Field Correction"
N4BiasFieldCorrection -d 3 \
	-i "${OUTPUT_DIR}/${FILENAME}.nii.gz" \
	-x "${OUTPUT_DIR}/${BRAIN_MASK_NAME}_binary.nii.gz" \
	-o [${OUTPUT_DIR}/${FILENAME}_biascorrected.nii.gz,${OUTPUT_DIR}/${FILENAME}_biasfield.nii.gz]

# Convert outputs back to Analzye format
echo "Converting image back to Analyze format"
fslchfiletype ANALYZE "${OUTPUT_DIR}/${FILENAME}_biascorrected.nii.gz" "${OUTPUT_DIR}/${FILENAME}_biascorrected.img"
fslchfiletype ANALYZE "${OUTPUT_DIR}/${FILENAME}_biasfield.nii.gz" "${OUTPUT_DIR}/${FILENAME}_biasfield.img"

echo "Done"
echo "Outputs saved in $OUTPUT_DIR:"
echo " - ${FILENAME}_biascorrected.nii.gz"
echo " - ${FILENAME}_biasfield.nii.gz"
echo " - ${FILENAME}_biascorrected.img/.hdr"
echo " - ${FILENAME}_biasfield.img/hdr"


