cp register_parcellations.sh register_parcellations.sh.bak 

mkdir -p output

# Register MPF brain to mprage brain. Create a registration transform
mri_robust_register \
	  --mov H05-2_MPFcor_freesurfer/mri/brain.mgz \
	  --dst H05-2_mprage1_freesurfer/mri/brain.mgz \
	  --lta output/H05-2_MPFcor_to_mprage.lta \
          --satit \
	  --mapmov output/brain_H05-2_MPFcor_in_mprage.mgz

# Resample MPF aparc+aseg into mprage space using transform
mri_vol2vol  \
	   --mov H05-2_MPFcor_freesurfer/mri/aparc+aseg.mgz \
	    --targ H05-2_mprage1_freesurfer/mri/aparc+aseg.mgz \
            --lta output/H05-2_MPFcor_to_mprage.lta \
            --o output/H05-2_MPFcor_aparc+aseg_reg_to_mprage.mgz  --nearest  

