#!/bin/bash
set -eu

NIFTI_DIR="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/nifti_outputs"
ROI_ROOT="/home/toddr/neva/MPF/Language_Mask/Language_ROIs_subject_specific"

OUTPUT_CSV="$ROI_ROOT/GM_Language_ROI_mean_MPF_native.csv"

echo "Subject,Mean_MPF" > "$OUTPUT_CSV"

for SUBJECT_DIR in "$ROI_ROOT"/H*; do

    ID=$(basename "$SUBJECT_DIR")

    NATIVE_DIR="$SUBJECT_DIR/native"

    MPF="$NIFTI_DIR/${ID}_reg_MPFcor_flipped.nii.gz"

    BROCA="$NATIVE_DIR/Broca_native.nii.gz"
    WERNICKE="$NATIVE_DIR/Wernicke_native.nii.gz"

    LANGUAGE_MASK="$NATIVE_DIR/${ID}_Language_ROIs_native.nii.gz"
    THRESHOLD_MASK="$NATIVE_DIR/${ID}_Language_ROIs_MPFge200.nii.gz"

    echo "Processing $ID"

    # Combine Broca and Wernicke masks into one binary mask
    fslmaths "$BROCA" -add "$WERNICKE" -bin "$LANGUAGE_MASK"

    # Retain only ROI voxels with MPF values >= 200
    fslmaths "$MPF" -thr 200 -bin -mul "$LANGUAGE_MASK" "$THRESHOLD_MASK"

    # Calculate mean MPF within the thresholded language ROI
    MEAN_MPF=$(fslstats "$MPF" -k "$THRESHOLD_MASK" -M)

    # Append results to CSV
    echo "$ID,$MEAN_MPF" >> "$OUTPUT_CSV"

    echo "  Mean MPF: $MEAN_MPF"

done

echo
echo "Processing completed."
echo "Results saved to: $OUTPUT_CSV"
