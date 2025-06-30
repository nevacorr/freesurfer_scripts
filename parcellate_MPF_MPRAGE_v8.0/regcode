# Register two parcellations of the same subject using the same modality (eg both mprage) 

#mri_coreg --mov H02-2_mprage1_freesurfer/mri/rawavg.mgz --ref H02-1_mprage1_freesurfer/mri/rawavg.mgz --reg tmp_H02_mprage_reg.lta


#mri_vol2vol --mov H02-2_mprage1_freesurfer/mri/aparc+aseg.mgz --targ H02-1_mprage1_freesurfer/mri/rawavg.mgz  --reg tmp_H02_mprage_reg.lta  --o tmp_H02-2_mprage_aseg2_coreg.mgz --interp nearest

# Register two parcellations  of the same subject, one that is from  mpf and the other that is from mprage

mri_robust_register --mov H02-1_MPFcor_freesurfer/mri/rawavg.mgz \
			--dst H02-1_mprage1_freesurfer/mri/rawavg.mgz \
 			--lta tmpdir/H02-tp1_mpf2mprage.lta \
			--satit

mri_vol2vol --mov H02-1_MPFcor_freesurfer/mri/aparc+aseg.mgz \
		--targ H02-1_mprage1_freesurfer/mri/aparc+aseg.mgz \
		--lta tmpdir/H02-tp1_mpf2mprage.lta \
		--o tmpdir/H02-tp1_aseg_mpf_coreg.mgz \
		--interp nearest

echo "Saved tmpdir/H02-tp1_aseg_mpf_coreg.mgz"
mri_seg_overlap --measures dice jaccard H02-1_mprage1_freesurfer/mri/aparc+aseg.mgz tmpdir/H02-tp1_aseg_mpf_coreg.mgz
