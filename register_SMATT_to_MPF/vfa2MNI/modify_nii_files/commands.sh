 1940  echo nohup antsBrainExtraction.sh -d 3 -a nii_files/VFA2_N4.nii.gz  -e MNI152_T1_1mm_brain.nii.gz -m MNI152_T1_1mm_brain_mask.nii.gz -o nii_files/VFA2_ants_be_ >BE.sh
 
# Convert MPFcor flipped and bias corrected image to a binary mask
2039  fslmaths MPFcor_N4.nii.gz -bin MPFcor_N4_mask.nii.gz
# Take MPFcorr bias corrected image and segmennt CSF, gray and white matter tissue
 2043  Atropos -d 3 -a MPFcor_N4.nii.gz -x MPFcor_N4_mask.nii.gz -c [5,0.0001] -i kmeans[3] -o [segmentations.nii.gz,prob%02d.nii.gz]
# Add together the GM and WM images
 2049  fslmaths prob02.nii.gz -add prob03.nii.gz -thr 0.5 -bin MPF_brain_prob_bin.nii.gz
# Erode combined GM and WM image to remove dura matter
 2051  fslmaths MPF_brain_prob_bin.nii.gz -ero MPF_brain_prob_bin_ero.nii.gz
# Dilatee eroded image 
 			2057  fslmaths MPF_brain_prob_bin.nii.gz -s 1 MPF_brain_smooth.nii.gz
 			2059  fslmaths MPF_brain_smooth.nii.gz -ero MPF_brain_smooth_ero_.nii.gz
fslmaths MPF_brain_prob_bin_ero.nii.gz -dilM MPF_brain_prob_bin_ero_dil.nii.gz
# Register dilated image to MNI adjusted template
# Use same transform to register MPFcor flipped nii files to the MNI adj template
