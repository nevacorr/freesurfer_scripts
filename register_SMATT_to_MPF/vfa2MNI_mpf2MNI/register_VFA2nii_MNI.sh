#!/bin/bash

# Usage: 
#conda activate ants
#nohup bash register_VFA2_MNI.sh >ants_registration.log 2>&1 &

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8

INPUT_IMG=nii_files/VFA2_flipped.nii.gz
BASE=$(basename "$INPUT_IMG" .nii.gz)
MPF_IMG=nii_files/MPFcor_flipped.nii.gz
MPF_N4cor=nii_files/MPFcor_N4.nii.gz

# Convert MPFcor flippd and bias corrected image to a binary mask for Atropos
#fslmaths ${MPF_N4cor} -bin nii_files/MPFcor_N4_mask.nii.gz

# Take MPFcorr bias corrected image and segment CSF gray and white matter 
#Atropos -d 3 -a ${MPF_N4cor} -x nii_files/MPFcor_N4_mask.nii.gz -c [5,0.0001] -i kmeans[3] -o [segmentation.nii.gz,prob%02d.nii.gz]

# Add together the GM and WM images
#fslmaths prob02.nii.gz -add prob03.nii.gz -thr 0.5 -bin nii_files/MPF_brain_prob_bin.nii.gz

# Erode combined GM and WM image to remove dura matter
#fslmaths nii_files/MPF_brain_prob_bin.nii.gz -ero nii_files/MPF_brain_prob_bin_ero.nii.gz

# Dilate eroded image
#fslmaths nii_files/MPF_brain_prob_bin_ero.nii.gz -dilM nii_files/MPF_brain_prob_bin_ero_dil.nii.gz 

# Apply  this mask to VFA flipped image
fslmaths ${INPUT_IMG} -mas nii_files/MPF_brain_prob_bin_ero_dil.nii.gz  nii_files/${BASE}_masked.nii.gz

#Bias correct masked VFA image
N4BiasFieldCorrection -d 3 -i nii_files/${BASE}_masked.nii.gz -o nii_files/${BASE}_masked_N4.nii.gz	

FIXED=files_from_vasily/MNI152_T1_1mm_brain-better-aligned.nii.gz
MOVING=nii_files/${BASE}_masked_N4.nii.gz
OUT=${BASE}_masked_2_mniadj_
MPF_REG_TO_MNI=MPF_flipped_reg_to_mniadj.nii.gz

antsRegistration \
 --dimensionality 3 \
 --float 0 \
 --output [${OUT},${OUT}Warped.nii.gz] \
 --interpolation Linear \
 --winsorize-image-intensities [0.005, 0.995] \
 --use-histogram-matching 1 \
 --initial-moving-transform [${FIXED},${MOVING},1] \
 --transform Rigid[0.1] \
   --metric Mattes[${FIXED},${MOVING},1,32,Regular,0.25] \
   --convergence [1000x500x250x0,1e-6,10] \
   --shrink-factors 8x4x2x1 \
   --smoothing-sigmas 3x2x1x0vox \
 --transform Affine[0.1] \
   --metric Mattes[${FIXED},${MOVING},1,32,Regular,0.25] \
   --convergence [100x70x50x20,1e-6,10] \
   --shrink-factors 8x4x2x1 \
   --smoothing-sigmas 3x2x1x0vox \
 --transform SyN[0.1,3,0] \
   --metric Mattes[${FIXED},${MOVING},1,32] \
   --convergence [100x70x50x20,1e-6,10] \
   --shrink-factors 8x4x2x1 \
   --smoothing-sigmas 3x2x1x0vox

antsApplyTransforms -d 3 \
 -i ${MPF_IMG} \
 -r ${FIXED} \
 -o ${MPF_REG_TO_MNI} \
 -n Linear \
 -t ${BASE}_masked_2_mniadj_1Warp.nii.gz \
 -t ${BASE}_masked_2_mniadj_0GenericAffine.mat

