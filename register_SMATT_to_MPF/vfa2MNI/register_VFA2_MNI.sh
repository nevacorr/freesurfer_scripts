#!/bin/bash

# Usage: 
#conda activate ants
#nohup bash register_VFA2_MNI.sh >ants_registration.log 2>&1 &

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THEADS=8

INPUT_IMG=H05-2/VFA2.hdr
BASE=$(basename "$INPUT_IMG" .hdr)

# Load sform/qform from reference image
sform_matrix=$(fslorient -getsform MT.nii)
qform_matrix=$(fslorient -getqform MT.nii)
read -r -a sform_array <<< "$sform_matrix"
read -r -a qform_array <<< "$qform_matrix"

mkdir -p nii_files

# Convert from analyze to nifti format
fslchfiletype NIFTI_GZ ${INPUT_IMG} nii_files/${BASE}.nii.gz

# Swap axes
echo "Swapping axes"	
fslswapdim nii_files/${BASE}.nii.gz -z -x -y nii_files/${BASE}_flipped.nii.gz

# Apply orientation from reference
echo "Applying orientation from reference MT.nii"
fslorient -setsform "${sform_array[@]}" nii_files/${BASE}_flipped.nii.gz
fslorient -setqform "${qform_array[@]}" nii_files/${BASE}_flipped.nii.gz
fslorient -setsformcode 1 nii_files/${BASE}_flipped.nii.gz
fslorient -setqformcode 1 nii_files/${BASE}_flipped.nii.gz

# Skull strip VFA volume
antsBrainExtraction.sh \
 -d 3 \
 -a nii_files/${BASE}_flipped.nii.gz \
 -e MNI152_T1_1mm.nii.gz \
 -m MNI152_T1_1mm_brain.nii.gz \ 
 -o nii_files/${BASE}

#Bias correct MPF map
N4BiasFieldCorrection -d 3 -i nii_files/${BASE}_BrainExtractionBrain.nii.gz -o nii_files/${BASE}_N4.nii.gz	

# Register FA map to MPF
FIXED=files_from_vasily/MNI152_T1_1mm_brain-better-aligned.nii.gz
MOVING=nii_files/${BASE}_N4.nii.gz
OUT=${BASE}_2_mniadj_

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

