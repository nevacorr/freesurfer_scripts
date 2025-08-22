import os
import nibabel as nib
import numpy as np

output_dir = 'diff_regions/H05-2/'
os.makedirs(output_dir, exist_ok=True)
multi_diff_file = os.path.join(output_dir, 'all_regions_diff.mgz')

lut_file = os.path.join(os.environ['FREESURFER_HOME'], 'FreeSurferColorLUT.txt')
exclude_keywords = ['unknown', 'wm-', 'unused', 'long', 'short', 'part', 'granular', 'layer']

subcortical_label_nums = [10, 11, 12, 13, 49, 50, 51, 52]
cortical_ranges = [(1000,1036), (2000,2036)]

label_dict = {}
with open(lut_file) as f:
	for line in f:
		if line.startswith('#') or not line.strip():
			continue
		parts = line.strip().split()
		label_num = int(parts[0])
		label_name = parts[1]

		if any(ex in label_name for ex in exclude_keywords):
			continue

		if label_num in subcortical_label_nums:
			label_dict[label_num] = label_name
			continue

		if any(start <= label_num <= end for (start,end) in cortical_ranges):
			label_dict[label_num] = label_name

# Load parcellations

img1 = nib.load('H05-2_mprage1_freesurfer/mri/aparc+aseg.mgz')
img2 = nib.load('output/H05-2_MPFcor_aparc+aseg_reg_to_mprage.mgz')
data1 = img1.get_fdata().astype(np.int32)
data2 = img2.get_fdata().astype(np.int32)

diff_volume = np.zeros(data1.shape, dtype=np.int16)

# Loop over labels and compute XOR
for label_num, region_name in label_dict.items():

	if label_num == 0:
		continue
	
	mask1 = (data1 == label_num)
	mask2 = (data2 == label_num)
	diff_mask = np.logical_xor(mask1, mask2)

	voxels_img1 = mask1.sum()
	voxels_img2 = mask2.sum()
	voxels_diff = diff_mask.sum()
	
	if voxels_diff > 0:
		diff_volume[diff_mask] = label_num

	print(f'{region_name}: numvox_img1={voxels_img1} numvox_img2={voxels_img2}, num differing voxels={voxels_diff}')

# Make a new header
new_header  = img1.header.copy()
new_header.set_data_dtype(np.int16)

out_img = nib.MGHImage(diff_volume, img1.affine, header=new_header)
out_img.to_filename(multi_diff_file)

print(f'multiregion diff file saved')

