#!/bin/bash

set -eu

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

FS_ROOT="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/freesurfer_output"

NIFTI_DIR="/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/newrecon_reg_to_PD/nifti_outputs"

ANT_ROOT="/home/toddr/neva/MPF/Language_Mask/SEG_REPRO_reg_to_MNI_lang"

OUT="/home/toddr/neva/MPF/Language_Mask/Language_ROIs_subject_specific"

# ------------------------------------------------------------
# FreeSurfer label IDs
# ------------------------------------------------------------

LUT="$FREESURFER_HOME/FreeSurferColorLUT.txt"

get_label_id() {
    awk -v label="$1" '$2 == label {print $1; exit}' "$LUT"
}

# DK labels
BROCA_OPERCULARIS=$(get_label_id "ctx-lh-parsopercularis")
BROCA_TRIANGULARIS=$(get_label_id "ctx-lh-parstriangularis")

# Destrieux labels
LATERAL_STG=$(get_label_id "ctx_lh_G_temp_sup-Lateral")
TRANSVERSE_TEMPORAL=$(get_label_id "ctx_lh_G_temp_sup-G_T_transv")

echo "Using FreeSurfer labels:"
echo "  Pars opercularis: $BROCA_OPERCULARIS"
echo "  Pars triangularis: $BROCA_TRIANGULARIS"
echo "  Lateral STG: $LATERAL_STG"
echo "  Transverse temporal: $TRANSVERSE_TEMPORAL"

mkdir -p "$OUT"

# ------------------------------------------------------------
# Process each FreeSurfer subject
# ------------------------------------------------------------

for FS_SUB in "$FS_ROOT"/H*_reg_MPFcor_freesurfer; do

    ID=$(basename "$FS_SUB" _reg_MPFcor_freesurfer)

    echo
    echo "============================================================"
    echo "Processing subject: $ID"
    echo "============================================================"

    # Input files

    ORIG="$FS_SUB/mri/orig/001.mgz"

    DK="$FS_SUB/mri/aparc+aseg.mgz"

    DESTRIEUX="$FS_SUB/mri/aparc.a2009s+aseg.mgz"

    NATIVE_MPF="$NIFTI_DIR/${ID}_reg_MPFcor_flipped.nii.gz"

    ANT_SUB="$ANT_ROOT/${ID}_reg"

    AFFINE="$ANT_SUB/${ID}_reg_masked_2_mni_0GenericAffine.mat"

    WARP="$ANT_SUB/${ID}_reg_masked_2_mni_1Warp.nii.gz"

    MNI_MPF="$ANT_SUB/${ID}_reg_reg_to_mni.nii.gz"

    # Output directories

    NATIVE_OUT="$OUT/$ID/native"
    MNI_OUT="$OUT/$ID/MNI"

    mkdir -p "$NATIVE_OUT" "$MNI_OUT"

    # Copy MNI MPF image to output folder for overlay visualization
    cp "$MNI_MPF" "$MNI_OUT/${ID}_reg_reg_to_mni.nii.gz"

    # --------------------------------------------------------
    # Resample subject-specific FreeSurfer parcellations
    # to native MPF geometry
    # --------------------------------------------------------

    echo "Resampling DK parcellation..."

    mri_vol2vol \
        --mov "$DK" \
        --targ "$ORIG" \
        --regheader \
        --interp nearest \
        --o "$NATIVE_OUT/DK_native.nii.gz"

    echo "Resampling Destrieux parcellation..."

    mri_vol2vol \
        --mov "$DESTRIEUX" \
        --targ "$ORIG" \
        --regheader \
        --interp nearest \
        --o "$NATIVE_OUT/Destrieux_native.nii.gz"

    # --------------------------------------------------------
    # Create native-space Broca and Wernicke masks
    # --------------------------------------------------------

    echo "Creating native-space language masks..."

    python - \
        "$NATIVE_OUT/DK_native.nii.gz" \
        "$NATIVE_OUT/Destrieux_native.nii.gz" \
        "$NATIVE_OUT/Broca_native.nii.gz" \
        "$NATIVE_OUT/Wernicke_native.nii.gz" \
        "$BROCA_OPERCULARIS" \
        "$BROCA_TRIANGULARIS" \
        "$LATERAL_STG" \
        "$TRANSVERSE_TEMPORAL" <<'PYTHON'

import sys
import numpy as np
import nibabel as nib

dk_file = sys.argv[1]
destrieux_file = sys.argv[2]
broca_file = sys.argv[3]
wernicke_file = sys.argv[4]

pars_opercularis = int(sys.argv[5])
pars_triangularis = int(sys.argv[6])
lateral_stg = int(sys.argv[7])
transverse_temporal = int(sys.argv[8])

# Load parcellations
dk_img = nib.load(dk_file)
destrieux_img = nib.load(destrieux_file)

dk = np.asanyarray(dk_img.dataobj)
destrieux = np.asanyarray(destrieux_img.dataobj)

# Broca: pars opercularis + pars triangularis
broca = np.logical_or(
    dk == pars_opercularis,
    dk == pars_triangularis
).astype(np.uint8)

# Wernicke: posterior portion of lateral STG
# Anterior boundary is the posterior edge of transverse temporal gyrus.

stg_coords = np.column_stack(np.where(destrieux == lateral_stg))
transverse_coords = np.column_stack(
    np.where(destrieux == transverse_temporal)
)

affine = destrieux_img.affine

transverse_ras = nib.affines.apply_affine(
    affine, transverse_coords
)

stg_ras = nib.affines.apply_affine(
    affine, stg_coords
)

# Smaller/more negative RAS Y is posterior.
posterior_edge = np.min(transverse_ras[:, 1])

posterior_stg = stg_coords[
    stg_ras[:, 1] < posterior_edge
]

wernicke = np.zeros(destrieux.shape, dtype=np.uint8)

if posterior_stg.shape[0] > 0:
    wernicke[
        posterior_stg[:, 0],
        posterior_stg[:, 1],
        posterior_stg[:, 2]
    ] = 1

# Save native-space masks
broca_img = nib.Nifti1Image(
    broca, dk_img.affine, dk_img.header
)
broca_img.set_data_dtype(np.uint8)
nib.save(broca_img, broca_file)

wernicke_img = nib.Nifti1Image(
    wernicke, destrieux_img.affine, destrieux_img.header
)
wernicke_img.set_data_dtype(np.uint8)
nib.save(wernicke_img, wernicke_file)

sys.stdout.write("Broca voxels: %d\n" % np.sum(broca))
sys.stdout.write("Wernicke voxels: %d\n" % np.sum(wernicke))
sys.stdout.write(
    "Posterior edge RAS Y: %.4f\n" % posterior_edge
)

PYTHON

    # --------------------------------------------------------
    # Transform native masks into MNI space
    # --------------------------------------------------------

    echo "Transforming Broca mask to MNI space..."

    antsApplyTransforms \
        -d 3 \
        -i "$NATIVE_OUT/Broca_native.nii.gz" \
        -r "$MNI_MPF" \
        -o "$MNI_OUT/Broca_MNI.nii.gz" \
        -n NearestNeighbor \
        -t "$WARP" \
        -t "$AFFINE"

    echo "Transforming Wernicke mask to MNI space..."

    antsApplyTransforms \
        -d 3 \
        -i "$NATIVE_OUT/Wernicke_native.nii.gz" \
        -r "$MNI_MPF" \
        -o "$MNI_OUT/Wernicke_MNI.nii.gz" \
        -n NearestNeighbor \
        -t "$WARP" \
        -t "$AFFINE"

    # --------------------------------------------------------
    # Create combined MNI overlay
    #
    # Broca = 1
    # Wernicke = 1
    # Overlap = 1
    # Background = 0
    # --------------------------------------------------------

    echo "Creating combined language ROI overlay..."

    fslmaths \
        "$MNI_OUT/Broca_MNI.nii.gz" \
        -bin \
        -add "$MNI_OUT/Wernicke_MNI.nii.gz" \
        -bin \
        "$MNI_OUT/${ID}_Language_ROIs_overlay_MNI.nii.gz"

    echo "Finished subject: $ID"

done

echo
echo "Processing completed."
echo "Output directory: $OUT"
