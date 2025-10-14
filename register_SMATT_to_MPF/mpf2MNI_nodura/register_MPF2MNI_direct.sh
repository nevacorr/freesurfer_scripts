#!/bin/bash

## Usage: 
##conda activate ants
##nohup bash register_VFA2_MNI.sh >ants_registration.log 2>&1 &

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=8
#
## Exit code on error
set -e

INPUT_IMG=H05-2/MPFcor.hdr
BASE=$(basename "$INPUT_IMG" .hdr)
FLIPPED_IMG=nii_files/${BASE}_flipped.nii.gz
FLIPPED_N4_IMG=nii_files/${BASE}_flipped_N4.nii.gz
MASKED_FLIPPED_N4_IMG=nii_files/${BASE}_flipped_N4_nodura.nii.gz

## Load sform/qform from reference image
sform_matrix=$(fslorient -getsform MT.nii)
qform_matrix=$(fslorient -getqform MT.nii)
read -r -a sform_array <<< "$sform_matrix"
read -r -a qform_array <<< "$qform_matrix"

mkdir -p nii_files

# Convert from analyze to nifti format
fslchfiletype NIFTI_GZ ${INPUT_IMG} nii_files/${BASE}.nii.gz

# Swap axes
echo "Swapping axes"	
fslswapdim nii_files/${BASE}.nii.gz -z -x -y ${FLIPPED_IMG}

# Apply orientation from reference
echo "Applying orientation from reference MT.nii"
fslorient -setsform "${sform_array[@]}" ${FLIPPED_IMG}
fslorient -setqform "${qform_array[@]}" ${FLIPPED_IMG}
fslorient -setsformcode 1 ${FLIPPED_IMG}
fslorient -setqformcode 1 ${FLIPPED_IMG}

#Bias correct MPF map
echo "Performing bias field correction"
N4BiasFieldCorrection -d 3 -i ${FLIPPED_IMG} -o ${FLIPPED_N4_IMG}

# Convert MPFcor flipped and bias corrected image to a binary mask for Atropos
fslmaths ${FLIPPED_N4_IMG} -bin nii_files/N4_mask.nii.gz

# Take bias corrected image and segment CSF gray and white matter 
echo "Segment with Atropos"
Atropos -d 3 -a ${FLIPPED_N4_IMG} -x nii_files/N4_mask.nii.gz -c [5,0.0001] -i kmeans[3] -o [nii_files/segmentation.nii.gz,nii_files/prob%02d.nii.gz]

# Add together the GM and WM images
echo "Summing GM and WM"
fslmaths nii_files/prob02.nii.gz -add nii_files/prob03.nii.gz -thr 0.5 -bin nii_files/MPF_brain_prob_bin.nii.gz

# Erode combined GM and WM image to remove dura matter
echo "Eroding mask"
fslmaths nii_files/MPF_brain_prob_bin.nii.gz -ero nii_files/MPF_brain_prob_bin_ero.nii.gz

# Dilate eroded image
echo "Dilating mask"
fslmaths nii_files/MPF_brain_prob_bin_ero.nii.gz -dilM nii_files/MPF_brain_prob_bin_ero_dil.nii.gz 

# Apply  this mask that excludes dura to input N4 corrected flipped image
echo "Applying no duras mask"
fslmaths ${FLIPPED_N4_IMG} -mas nii_files/MPF_brain_prob_bin_ero_dil.nii.gz  ${MASKED_FLIPPED_N4_IMG}

FIXED=files_from_vasily/MNI152_T1_1mm_brain-better-aligned.nii.gz
MOVING=${MASKED_FLIPPED_N4_IMG}
OUT=nii_files/${BASE}_masked_2_mniadj_
MPF_REG_TO_MNI=nii_files/MPF_flipped_reg_to_mniadj.nii.gz

echo "Runnning ants registration"
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
 -i ${FLIPPED_IMG} \
 -r ${FIXED} \
 -o ${MPF_REG_TO_MNI} \
 -n Linear \
 -t ${BASE}_masked_2_mniadj_1Warp.nii.gz \
 -t ${BASE}_masked_2_mniadj_0GenericAffine.mat

