mri_robust_register --mov ../freesurfer_output/H06-2_MPFcor_freesurfer/mri/orig/001.mgz --dst ../freesurfer_output/H06-2_MPFcor_freesurfer/mri/rawavg.mgz --lta mpf2mprage.lta --satit --iscale

mri_vol2vol --mov ../freesurfer_output/H06-2_MPFcor_freesurfer/mri/orig/001.mgz --targ ../freesurfer_output/H06-2_MPFcor_freesurfer/mri/aparc+aseg.mgz --lta mpf2mprage.lta --o 001_in_aparcasegspace.mgz --interp trilinear

mri_segstats --seg ../freesurfer_output/H06-2_MPFcor_freesurfer/mri/aparc+aseg.mgz --in 001_in_aparcasegspace.mgz --ctab /usr/local/freesurfer/8.0.0/FreeSurferColorLUT.txt --sum output_mpf_stats.txt
