
# Load sform/qform from reference image
#sform_matrix=$(fslorient -getsform MT.nii)
#qform_matrix=$(fslorient -getqform MT.nii)
#read -r -a sform_array <<< "$sform_matrix"
#read -r -a qform_array <<< "$qform_matrix"

# Convert MPF and mprage from analyze to nifti format
#fslchfiletype NIFTI_GZ SEG_REPRO/H05-2/MPFcor.hdr nii_files/MPFcor.nii.gz
#fslchfiletype NIFTI_GZ SEG_REPRO/H05-2/mprage1.hdr nii_files/mprage1.nii.gz

# Swap axes
#fslswapdim nii_files/MPFcor.nii.gz -z -x -y nii_files/MPFcor_flipped.nii.gz
#fslswapdim nii_files/mprage1.nii.gz -z -x -y nii_files/mprage1_flipped.nii.gz

# Apply orientation from reference
#fslorient -setsform "${sform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setqform "${qform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setsformcode 1 nii_files/MPFcor_flipped.nii.gz
#fslorient -setqformcode 1 nii_files/MPFcor_flipped.nii.gz

#fslorient -setsform "${sform_array[@]}" nii_files/mprage1_flipped.nii.gz
#fslorient -setqform "${qform_array[@]}" nii_files/mprage1_flipped.nii.gz
#fslorient -setsformcode 1 nii_files/mprage1_flipped.nii.gz
#fslorient -setqformcode 1 nii_files/mprage1_flipped.nii.gz

# Generate binary brain mask from MPF image
#fslmaths nii_files/MPFcor_flipped.nii.gz -bin nii_files/MPFcor_flipped_mask.nii.gz

# Apply brain mask to the mprage
#fslmaths nii_files/mprage1_flipped.nii.gz -mas nii_files/MPFcor_flipped_mask.nii.gz nii_files/mprage1_flipped_brain.nii.gz

#flirt -in nii_files/MPFcor_flipped.nii.gz -ref /Users/nevao/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz -out nii_files/MPFcor_flipped_linear_reg.nii.gz -omat nii_files/MPFcor_flipped2MNI.mat -dof 12 -cost corratio

#fnirt --in=nii_files/MPFcor_flipped.nii.gz --aff=nii_files/MPFcor_flipped2MNI.mat --ref=/Users/nevao/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz --iout=nii_files/MPF_flipped_nonlinear.nii.gz --fout=nii_files/MPF_flipped_warpcoef.nii.gz

#flirt -in nii_files/mprage1_flipped.nii.gz -ref /Users/nevao/fsl/data/standard/MNI152_T1_1mm.nii.gz -out nii_files/mprage1_linear_reg_to_MNI.nii.gz -omat nii_files/mprage2MNI_affine.mat -dof 12

#fnirt --in=nii_files/mprage1_flipped.nii.gz --aff=nii_files/mprage2MNI_affine.mat --ref=/Users/nevao/fsl/data/standard/MNI152_T1_1mm.nii.gz --iout=mprage1_nonlinear_toMNI.nii.gz --fout=nii_files/mprage2MNI_warpcoef.nii.gz

applywarp -i nii_files/MPFcor_flipped.nii.gz -r /Users/nevao/fsl/data/standard/MNI152_T1_1mm.nii.gz -w nii_files/mprage2MNI_warpcoef.nii.gz -o nii_files/MPFcor_in_MNI.nii.gz
