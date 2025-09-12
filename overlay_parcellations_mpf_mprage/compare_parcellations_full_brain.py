import sys
import os
import nibabel as nib
import numpy as np

if len(sys.argv) !=3:
	print("Usage: python compare_parcellations_full_brain.py <mprage_img> <mpf_img>")
	sys.exit(1)

mprage_path = sys.argv[1]
mpf_path = sys.argv[2]

output_dir = 'diff_regions/'
os.makedirs(output_dir, exist_ok=True)

mprage_name = os.path.basename(mprage_path).replace('.mgz', '')
mpf_name = os.path.basename(mpf_path).replace('.mgz', '')
output_file = os.path.join(output_dir, f'diff_{mprage_name}_vs_{mpf_name}.mgz')

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
img1 = nib.load(mprage_path)
img2 = nib.load(mpf_path)
data1 = img1.get_fdata().astype(np.int32)
data2 = img2.get_fdata().astype(np.int32)

# Initialize diff volume
diff_volume = np.zeros(data1.shape, dtype=np.int16)

# Voxels in image 1 parcellation but not in or with different label in image 2 parcellation
image1_only = (data1 != 0) & (data2 != data1)
diff_volume[image1_only] = 1

# Voxels in image 2 parcellation but not in or with different label in image 1 parcellation
image2_only = (data2 != 0) & (data2 != data1)
diff_volume[image2_only] = 2

# Voxels in both parcellations but assigned to different parcels
different_label = (data1 != 0) & (data2 != 0) & (data1 != data2)
diff_volume[different_label] = 3

# Compute differences
for label_num, region_name in label_dict.items():

	if label_num == 0:
		continue
	
	mask1 = (data1 == label_num)
	mask2 = (data2 == label_num)
	voxels_img1 = mask1.sum()
	voxels_img2 = mask2.sum()
	voxels_diff = np.logical_xor(mask1, mask2).sum()
	
	print(f'{region_name}: numvox_mprage={voxels_img1} numvox_mpf={voxels_img2}, num differing voxels={voxels_diff}')

# Save as .mgz
new_header = img1.header.copy()
new_header.set_data_dtype(np.int16)
out_img = nib.MGHImage(diff_volume, img1.affine, header=new_header)
out_img.to_filename(output_file)
print(f'Saved output file {output_file}')

