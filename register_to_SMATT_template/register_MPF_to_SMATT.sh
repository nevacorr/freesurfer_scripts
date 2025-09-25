
# Load sform/qform from reference image
#sform_matrix=$(fslorient -getsform MT.nii)
#qform_matrix=$(fslorient -getqform MT.nii)
#read -r -a sform_array <<< "$sform_matrix"
#read -r -a qform_array <<< "$qform_matrix"
#
## Convert MPF from analyze to nifti format
#fslchfiletype NIFTI_GZ SEG_REPRO/H05-2/MPFcor.hdr nii_files/MPFcor.nii.gz
#
## Swap axes
#fslswapdim nii_files/MPFcor.nii.gz -z -x -y nii_files/MPFcor_flipped.nii.gz
#
## Apply orientation from reference
#fslorient -setsform "${sform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setqform "${qform_array[@]}" nii_files/MPFcor_flipped.nii.gz
#fslorient -setsformcode 1 nii_files/MPFcor_flipped.nii.gz
#fslorient -setqformcode 1 nii_files/MPFcor_flipped.nii.gz

flirt -in nii_files/MPFcor_flipped.nii.gz -ref /Users/nevao/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz -out nii_files/MPFcor_flipped_linear_reg.nii.gz -omat nii_files/MPFcor_flipped2MNI.mat -dof 12 -cost corratio

fnirt --in nii_files/MPFcor_flipped.nii.gz --aff nii_files/MPFcor_flipped2MNI.mat --ref /Users/nevao/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz --iout=nii_files/MPF_flipped_nonlinear.nii.gz --fout=nii_files/MPF_flipped_warpcoef.nii.gz
