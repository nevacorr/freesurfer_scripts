#!/bin/bash

export SUBJECTS_DIR=/home/toddr/neva/MPF/parcellate_MPF_MPRAGE_v8.0/freesurfer_output
 
cd $SUBJECTS_DIR

# Write cortical stats to file

aparcstats2table --hemi lh --meas volume  --tablefile mprage_left_hem_volumes.txt --subjects H02-1_mprage1_freesurfer H02-2_mprage1_freesurfer H03-1_mprage1_freesurfer H03-2_mprage1_freesurfer H04-2_mprage1_freesurfer H05-2_mprage1_freesurfer H06-1_mprage1_freesurfer H06-2_mprage1_freesurfer H07-1_mprage1_freesurfer H07-2_mprage1_freesurfer H08-1_mprage1_freesurfer H08-2_mprage1_freesurfer H10-1_mprage1_freesurfer H10-2_mprage1_freesurfer H13-2_mprage1_freesurfer H14-2_mprage1_freesurfer H15-1_mprage1_freesurfer

aparcstats2table --hemi rh --meas volume  --tablefile mprage_right_hem_volumes.txt --subjects H02-1_mprage1_freesurfer H02-2_mprage1_freesurfer H03-1_mprage1_freesurfer H03-2_mprage1_freesurfer H04-2_mprage1_freesurfer H05-2_mprage1_freesurfer H06-1_mprage1_freesurfer H06-2_mprage1_freesurfer H07-1_mprage1_freesurfer H07-2_mprage1_freesurfer H08-1_mprage1_freesurfer H08-2_mprage1_freesurfer H10-1_mprage1_freesurfer H10-2_mprage1_freesurfer H13-2_mprage1_freesurfer H14-2_mprage1_freesurfer H15-1_mprage1_freesurfer

aparcstats2table --hemi lh --meas volume  --tablefile mpf_left_hem_volumes.txt --subjects H02-1_MPFcor_freesurfer H02-2_MPFcor_freesurfer H03-1_MPFcor_freesurfer H03-2_MPFcor_freesurfer H04-1_MPFcor_freesurfer H04-2_MPFcor_freesurfer H05-1_MPFcor_freesurfer H05-2_MPFcor_freesurfer H06-1_MPFcor_freesurfer H06-2_MPFcor_freesurfer H07-1_MPFcor_freesurfer H07-2_MPFcor_freesurfer H08-1_MPFcor_freesurfer H08-2_MPFcor_freesurfer H10-1_MPFcor_freesurfer H10-2_MPFcor_freesurfer H13-1_MPFcor_freesurfer H13-2_MPFcor_freesurfer H14-1_MPFcor_freesurfer H14-2_MPFcor_freesurfer H15-1_MPFcor_freesurfer H15-2_MPFcor_freesurfer

aparcstats2table --hemi rh --meas volume  --tablefile mpf_right_hem_volumes.txt --subjects H02-1_MPFcor_freesurfer H02-2_MPFcor_freesurfer H03-1_MPFcor_freesurfer H03-2_MPFcor_freesurfer H04-1_MPFcor_freesurfer H04-2_MPFcor_freesurfer H05-1_MPFcor_freesurfer H05-2_MPFcor_freesurfer H06-1_MPFcor_freesurfer H06-2_MPFcor_freesurfer H07-1_MPFcor_freesurfer H07-2_MPFcor_freesurfer H08-1_MPFcor_freesurfer H08-2_MPFcor_freesurfer H10-1_MPFcor_freesurfer H10-2_MPFcor_freesurfer H13-1_MPFcor_freesurfer H13-2_MPFcor_freesurfer H14-1_MPFcor_freesurfer H14-2_MPFcor_freesurfer H15-1_MPFcor_freesurfer H15-2_MPFcor_freesurfer

# Write subcortical stats to file

asegstats2table --meas volume  --tablefile mprage_subcort_volumes.txt --subjects H02-1_mprage1_freesurfer H02-2_mprage1_freesurfer H03-1_mprage1_freesurfer H03-2_mprage1_freesurfer H04-2_mprage1_freesurfer H05-2_mprage1_freesurfer H06-1_mprage1_freesurfer H06-2_mprage1_freesurfer H07-1_mprage1_freesurfer H07-2_mprage1_freesurfer H08-1_mprage1_freesurfer H08-2_mprage1_freesurfer H10-1_mprage1_freesurfer H10-2_mprage1_freesurfer H13-2_mprage1_freesurfer H14-2_mprage1_freesurfer H15-1_mprage1_freesurfer

asegstats2table --meas volume  --tablefile mpf_subcort_volumes.txt --subjects H02-1_MPFcor_freesurfer H02-2_MPFcor_freesurfer H03-1_MPFcor_freesurfer H03-2_MPFcor_freesurfer H04-1_MPFcor_freesurfer H04-2_MPFcor_freesurfer H05-1_MPFcor_freesurfer H05-2_MPFcor_freesurfer H06-1_MPFcor_freesurfer H06-2_MPFcor_freesurfer H07-1_MPFcor_freesurfer H07-2_MPFcor_freesurfer H08-1_MPFcor_freesurfer H08-2_MPFcor_freesurfer H10-1_MPFcor_freesurfer H10-2_MPFcor_freesurfer H13-1_MPFcor_freesurfer H13-2_MPFcor_freesurfer H14-1_MPFcor_freesurfer H14-2_MPFcor_freesurfer H15-1_MPFcor_freesurfer H15-2_MPFcor_freesurfer
