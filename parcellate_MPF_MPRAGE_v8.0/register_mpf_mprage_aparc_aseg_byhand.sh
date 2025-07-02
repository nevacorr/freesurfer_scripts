

#mri_robust_register --mov tmp_coreg_mpfmprage/H03-2_tp2_mpf_resampled.mgz --dst freesurfer_output/H03-2_mprage1_freesurfer/mri/rawavg.mgz --lta tmp_coreg_mpfmprage/H03-2_tp2_mpf2mprage_byhand_resampled.lta --satit --iscale

#mri_vol2vol --mov tmp_coreg_mpfmprage/H03-2_tp2_aseg_mpf_resampled.mgz --targ freesurfer_output/H03-2_mprage1_freesurfer/mri/aparc+aseg.mgz --lta tmp_coreg_mpfmprage/H03-2_tp2_mpf2mprage_byhand_resampled.lta --o tmp_coreg_mpfmprage/H03-2_tp2_aseg_mpf_coreg_byhand_resampled.mgz --interp nearest

#mri_coreg --mov freesurfer_output/H03-2_MPFcor_freesurfer/mri/rawavg.mgz --ref freesurfer_output/H03-2_mprage1_freesurfer/mri/rawavg.mgz --reg tmp_coreg_mpfmprage/H03-2_mri_coreg_mpf_to_mprage.lta

#mri_vol2vol --mov freesurfer_output/H03-2_MPFcor_freesurfer/mri/aparc+aseg.mgz --targ freesurfer_output/H03-2_mprage1_freesurfer/mri/aparc+aseg.mgz --reg tmp_coreg_mpfmprage/H03-2_mri_coreg_mpf_to_mprage.lta --o tmp_coreg_mpfmprage/H03-2_tp2_aparc+aseg_coreg.mgz --interp nearest

#mri_mask freesurfer_output/H03-2_mprage1_freesurfer/mri/rawavg.mgz freesurfer_output/H03-2_mprage1_freesurfer/mri/brainmask.mgz tmp_coreg_mpfmprage/H03-2_mprage_rawavg_stripped.mgz

#mri_robust_register --mov freesurfer_output/H03-2_MPFcor_freesurfer/mri/rawavg.mgz -dst tmp_coreg_mpfmprage/H03-2_mprage_rawavg_stripped.mgz --lta tmp_coreg_mpfmprage/HO3-2_mpf2mprage_robust_skullstripped.lta --satit --iscale

mri_vol2vol --mov freesurfer_output/H03-2_MPFcor_freesurfer/mri/aparc+aseg.mgz --targ freesurfer_output/H03-2_mprage1_freesurfer/mri/aparc+aseg.mgz --lta tmp_coreg_mpfmprage/HO3-2_mpf2mprage_robust_skullstripped.lta --o tmp_coreg_mpfmprage/H03-2_tp2_aseg_mpf_coreg_stripped.mgz --interp nearest
