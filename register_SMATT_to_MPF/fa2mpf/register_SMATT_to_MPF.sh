#!/bin/bash

#conda activate ants

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THEADS=8
# Usage: nohup bash register_SMATT_to_MPF.sh >ants_registration.log 2>&1 &

# Load sform/qform from reference image
#sform_matrix=$(fslorient -getsform MT.nii)
#qform_matrix=$(fslorient -getqform MT.nii)
#read -r -a sform_array <<< "$sform_matrix"
#read -r -a qform_array <<< "$qform_matrix"

#mkdir -p nii_files

# Convert from analyze to nifti format
#fslchfiletype NIFTI_GZ H05-2/MPFcor.hdr nii_files/MPFcor.nii.gz

# Swap axes
#echo "Swapping axes"	
#fslswapdim nii_files/MPFcor.nii.gz -z -x -y nii_files/MPFcor_flipped.nii.gz

# Apply orientation from reference
#echo "Applying orientation from reference MT.nii"
#fslorient -setsform "${sform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setqform "${qform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setsformcode 1 nii_files/MPFcor_flipped.nii.gz
#fslorient -setqformcode 1 nii_files/MPFcor_flipped.nii.gz

#Bias correct MPF map
#N4BiasFieldCorrection -d 3 -i nii_files/MPFcor_flipped.nii.gz -o nii_files/MPFcor_N4.nii.gz	

# Register FA map to MPF
TEMPLATE_FA=files_from_Vasily/FMRIB58_FA_1mm.nii.gz
SUBJ_MPF=nii_files/MPFcor_N4.nii.gz
OUT=fa2mpf_
WM_TEMPLATE=files_from_Vasily/S-MATT_roi_lt_rt.nii
OUTMASK=WM_roi_lt_rt_on_subj_MPF.nii.gz

#antsRegistration \
# --dimensionality 3 \
# --float 0 \
# --output [${OUT},${OUT}Warped.nii.gz] \
# --interpolation Linear \
# --winsorize-image-intensities [0.005, 0.995] \
# --initial-moving-transform [${SUBJ_MPF},${TEMPLATE_FA},1] \
# --transform Rigid[0.1] \
#   --metric Mattes[${SUBJ_MPF},${TEMPLATE_FA},1,32,Regular,0.25] \
#   --convergence [1000x500x250x0,1e-6,10] \
#   --shrink-factors 8x4x2x1 \
#   --smoothing-sigmas 3x2x1x0vox \
# --transform Affine[0.1] \
#   --metric Mattes[${SUBJ_MPF},${TEMPLATE_FA},1,32,Regular,0.25] \
#   --convergence [100x70x50x20,1e-6,10] \
#   --shrink-factors 8x4x2x1 \
#   --smoothing-sigmas 3x2x1x0vox \
# --transform SyN[0.1,3,0] \
#   --metric Mattes[${SUBJ_MPF},${TEMPLATE_FA},1,32] \
#   --convergence [100x70x50x20,1e-6,10] \
#   --shrink-factors 8x4x2x1 \
#   --smoothing-sigmas 3x2x1x0vox

antsApplyTransforms -d 3 \
 -i ${WM_TEMPLATE} \
 -r ${SUBJ_MPF} \
 -o ${OUTMASK} \
 -n NearestNeighbor \
 -t fa2mpf_1Warp.nii.gz \
 -t fa2mpf_0GenericAffine.mat
