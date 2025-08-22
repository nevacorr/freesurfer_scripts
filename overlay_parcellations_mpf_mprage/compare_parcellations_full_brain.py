import os
import nibabel as nib
import numpy as np

output_dir = 'diff_regions/H05-2/'
os.makedirs(output_dir, exist_ok=True)

multi_diff_file = os.path.join(output_dir, 'all_regions_diff.mgz')

lut_file = os.path.join(os.environ['FREESURFER_HOME'], 'FreeSurferColorLUT.txt')
label_dict = {}
subcortical_keywords = ['Caudate', 'Putamen', 'Pallidum', 'Thalamus']
exclude_keywords = ['unknown', 'wm-', 'unused', 'long', 'short', 'part', 'granular', 'layer']

cortical_ranges = [(1000, 1999), (2000, 2999)]

with open(lut_file) as f:
	for line in f:
		if line.startswith('#') or not line.strip():
			continue
		parts = line.strip().split()
		label_num = int(parts[0])
		label_name = parts[1]

		if any(ex in label_name for ex in exclude_keywords):
			continue

		in_cortical_range = any(start <= label_num <= end for (start,end) in cortical_ranges)
		is_subcortical = any(k in label_name for k in subcortical_keywords)

		if in_cortical_range or is_subcortical:
			label_dict[label_num] = label_name

# Load parcellations

img1 = nib.load('H05-2_mprage1_freesurfer/mri/aparc+aseg.mgz')
img2 = nib.load('output/H05-2_MPFcor_aparc+aseg_reg_to_mprage.mgz')
data1 = img1.get_fdata()
data2 = img2.get_fdata()

diff_volume = np.zeros(data1.shape, dtype=np.int32)

# Loop over labels and compute XOR

for label_num, region_name in label_dict.items():

	if label_num == 0:
		continue
	
	mask1 = (data1 == label_num).astype(np.uint8)
	mask2 = (data2 == label_num).astype(np.uint8)

#	if not mask1.any() and not mask2.any():
#		continue

	diff_mask = np.logical_xor(mask1, mask2).astype(np.uint8)

	diff_volume[diff_mask] = label_num

	print(f'finished region {region_name}')

nib.MGHImage(diff_volume, img1.affine, header=img1.header).to_filename(multi_diff_file)	

print(f'multiregion diff file saved')

