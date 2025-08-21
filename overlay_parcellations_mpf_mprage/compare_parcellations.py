import os
import nibabel as nib
import numpy as np

output_dir = 'diff_regions/H05-2/'
os.makedirs(output_dir, exist_ok=True)

lut_file = os.path.join(os.environ['FREESURFER_HOME'], 'FreeSurferColorLUT.txt')
label_dict = {}
with open(lut_file) as f:
	for line in f:
		if line.startswith('#') or not line.strip():
			continue
		parts = line.strip().split()
		label_num = int(parts[0])
		label_name = parts[1]
		label_dict[label_num] = label_name

#labels = [
#	1001, 1002, 1003, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014,
#	1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027,
#	1028, 1029, 1030, 1031, 1034, 1035, 
#	2001, 2002, 2003, 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014,
#	2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 
#	2028, 2029, 2030, 2031, 2034, 2035 
#]

# Load parcellations

img1 = nib.load('H05-2_mprage1_freesurfer/mri/aparc+aseg.mgz')
img2 = nib.load('output/H05-2_MPFcor_aparc+aseg_reg_to_mprage.mgz')

data1 = img1.get_fdata()
data2 = img2.get_fdata()

# Loop over labels and compute XOR

for label_num, region_name in label_dict.items():

	if label_num == 0:
		continue
	
	mask1 = (data1 == label_num).astype(np.uint8)
	mask2 = (data2 == label_num).astype(np.uint8)

	if not mask1.any() and not mask2.any():
		continue

	diff = np.logical_xor(mask1, mask2).astype(np.uint8)

	mask1_filename = os.path.join(output_dir, f'{region_name}_mask_mprage.mgz')
	mask2_filename = os.path.join(output_dir, f'{region_name}_mask_MPFcor.mgz')
	diff_filename = os.path.join(output_dir, f'r{region_name}_diff.mgz')
	
	nib.MGHImage(mask1, img1.affine, header=img1.header).to_filename(mask1_filename)	
	nib.MGHImage(mask2, img2.affine, header=img1.header).to_filename(mask2_filename)	
	nib.MGHImage(diff, img1.affine, header=img1.header).to_filename(diff_filename)	

	print(f'files for {region_name} written')

