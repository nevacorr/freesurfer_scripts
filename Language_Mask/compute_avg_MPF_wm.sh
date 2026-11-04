#!/bin/bash
set -eu

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

FS_ROOT="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/freesurfer_output"

NIFTI_DIR="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/nifti_outputs"

ANT_ROOT="/home/toddr/neva/MPF/Language_Mask/SEG_REPRO_reg_to_MNI_lang"

ROI_ROOT="/home/toddr/neva/MPF/Language_Mask/Language_ROIs_subject_specific"

WM_DIR="/home/toddr/neva/MPF/Language_Mask/White_Matter_Mask"

WM_ATLAS="$WM_DIR/lang_xtract_atlas_left_3tracts.nii.gz"

OUTPUT_CSV="$WM_DIR/White_Matter_mean_MPF_native.csv"

mkdir -p "$WM_DIR"

echo "Subject,Mean_WM_MPF" > "$OUTPUT_CSV"

# ------------------------------------------------------------
# Process each FreeSurfer subject
# ------------------------------------------------------------

for FS_SUB in "$FS_ROOT"/H*_reg_MPFcor_freesurfer; do

    [ -d "$FS_SUB" ] || continue

    ID=$(basename "$FS_SUB" _reg_MPFcor_freesurfer)

    echo
    echo "============================================================"
    echo "Processing subject: $ID"
    echo "============================================================"

    # Input files

    ORIG="$FS_SUB/mri/orig/001.mgz"

    DK="$FS_SUB/mri/aparc+aseg.mgz"

    MPF="$NIFTI_DIR/${ID}_reg_MPFcor_flipped.nii.gz"

    cp "$MPF" "$WM_DIR/"

    ANT_SUB="$ANT_ROOT/${ID}_reg"

    AFFINE="$ANT_SUB/${ID}_reg_masked_2_mni_0GenericAffine.mat"

    INV_WARP="$ANT_SUB/${ID}_reg_masked_2_mni_1InverseWarp.nii.gz"

    # Output files

    ATLAS_NATIVE="$WM_DIR/${ID}_WM_atlas_native.nii.gz"

    FS_NATIVE="$WM_DIR/${ID}_FS_aparc_aseg_native.nii.gz"

    FS_WM="$WM_DIR/${ID}_FS_left_cerebral_WM_native.nii.gz"

    WM_INTERSECTION="$WM_DIR/${ID}_WM_atlas_FS_intersection.nii.gz"

    WM_FINAL="$WM_DIR/${ID}_WM_mask_final.nii.gz"

    # --------------------------------------------------------
    # Check inputs
    # --------------------------------------------------------

    for FILE in "$ORIG" "$DK" "$MPF" "$WM_ATLAS" \
                "$AFFINE" "$INV_WARP"; do
        if [ ! -f "$FILE" ]; then
            echo "ERROR: Missing file: $FILE"
            exit 1
        fi
    done

    # Copy native MPF image for visual inspection
    cp "$MPF" "$WM_DIR/"

    # --------------------------------------------------------
    # Resample FreeSurfer segmentation to native MPF geometry
    # --------------------------------------------------------

    echo "Resampling FreeSurfer segmentation..."

    mri_vol2vol \
        --mov "$DK" \
        --targ "$ORIG" \
        --regheader \
        --interp nearest \
        --o "$FS_NATIVE"

    # Extract left cerebral white matter (FreeSurfer label 2)

    echo "Extracting left cerebral white matter..."

    fslmaths "$FS_NATIVE" \
        -thr 2 -uthr 2 -bin \
        "$FS_WM"

    # --------------------------------------------------------
    # Transform MNI WM atlas into native MPF space
    # --------------------------------------------------------

    echo "Transforming WM atlas to native space..."

    antsApplyTransforms \
        -d 3 \
        -i "$WM_ATLAS" \
        -r "$MPF" \
        -o "$ATLAS_NATIVE" \
        -n NearestNeighbor \
        -t "[$AFFINE,1]" \
        -t "$INV_WARP"

    fslmaths "$ATLAS_NATIVE" -bin "$ATLAS_NATIVE"

    # --------------------------------------------------------
    # Intersect atlas with FreeSurfer white matter
    # --------------------------------------------------------

    echo "Intersecting atlas with FreeSurfer white matter..."

    fslmaths "$ATLAS_NATIVE" \
        -mul "$FS_WM" \
        -bin \
        "$WM_INTERSECTION"

    # --------------------------------------------------------
    # Apply MPF threshold (MPF >= 200)
    # --------------------------------------------------------

    echo "Applying MPF threshold..."

    fslmaths "$MPF" \
        -thr 200 -bin \
        -mul "$WM_INTERSECTION" \
        "$WM_FINAL"

    # --------------------------------------------------------
    # Calculate mean MPF
    # --------------------------------------------------------

    MEAN_MPF=$(fslstats "$MPF" -k "$WM_FINAL" -M)

    echo "$ID,$MEAN_MPF" >> "$OUTPUT_CSV"

    echo "Mean WM MPF: $MEAN_MPF"

done

echo
echo "Processing completed."
echo "Results saved to: $OUTPUT_CSV"

