import sys
import os
import nibabel as nib
import numpy as np
import pandas as pd

if len(sys.argv) !=3:
	print("Usage: python compare_parcellations_full_brain.py <mprage_img> <mpf_img>")
	sys.exit(1)

mprage_path = sys.argv[1]
mpf_path = sys.argv[2]

output_dir = 'diff_regions/'
os.makedirs(output_dir, exist_ok=True)

mprage_path_safe = mprage_path.replace('/', '_').replace('\\', '_')
mpf_name = os.path.basename(mpf_path).replace('.mgz', '')
output_file = os.path.join(output_dir, f'diff_{mprage_path_safe}_vs_{mpf_name}.mgz')

# Load parcellations
img1 = nib.load(mprage_path)
img2 = nib.load(mpf_path)
data1 = img1.get_fdata().astype(np.int32)
data2 = img2.get_fdata().astype(np.int32)

# Initialize diff volume
diff_volume = np.zeros(data1.shape, dtype=np.int16)

# Labels
wm_labels = [2, 41]
gm_labels = list(range(1000, 1036)) + list(range(2000, 2036)) #cortical
gm_labels += [10, 11, 12, 13, 49, 50, 51, 52] # subcortical
csf_labels = [4, 43, 14, 15, 24, 31, 63]

# Masks
wm_mask1 = np.isin(data1, wm_labels)
wm_mask2 = np.isin(data2, wm_labels)
csf_mask1 = np.isin(data1, csf_labels)
csf_mask2 = np.isin(data2, csf_labels)

def classify(label):
	if label in wm_labels:
		return 1 # WM
	elif label in gm_labels:
		return 2 # GM
	elif label in csf_labels:
		return 3 # CSF
	else:
		return 0 # ignore, background or non-interest	
	

# Map voxel labels into WM/ GM/ CSF/ other
class1 = np.vectorize(classify)(data1)
class2 = np.vectorize(classify)(data2)

# Build difference map
diff_volume = np.zeros(data1.shape, dtype=np.int16)

# WM in img1 to GM in img2
diff_volume[(class1 == 1) & (class2 == 2)] = 1
# GM in img1 to WM in img2
diff_volume[(class1 == 2) & (class2 == 1)] = 2
# CSF in img1 to WM or GM in img2
diff_volume[(class1 == 3) & ((class2 == 1) | (class2 == 2))] = 3
# WM or GM in img1, to CSF in img2 
diff_volume[((class1 == 1) | (class1 == 2)) & (class2 == 3)] = 4

# Make categories variable for calculating sum for each category
categories = {
	1: "WM in MPRAGE - GM in MPF", 
	2: "GM in MPRAGE - WM in MPF",
	3: "CSF in MPRAGE - GM/WM in MPF",
	4: "GM/WM in MPRAGE - CSF in MPF"
}

# Construct counts text file name
counts_file_name = os.path.join(
	os.path.dirname(output_file), 												'count_' + os.path.basename(output_file).replace('.mgz', '.txt')
)

# Write counts to file
with open(counts_file_name, 'w') as f:
	f.write("Category\tVoxel Count\n")
	total_voxels = 0
	for code, desc in categories.items():
		n_voxels = np.sum(diff_volume == code)
		total_voxels += n_voxels
		f.write(f"{desc}\t{n_voxels}\n")
	f.write(f"Total\t{total_voxels}\n")

# Save as diff_volume as .mgz
new_header = img1.header.copy()
new_header.set_data_dtype(np.int16)
out_img = nib.MGHImage(diff_volume, img1.affine, header=new_header)
out_img.to_filename(output_file)

print(f'Saved output files {output_file} and {counts_file_name}')

confusion = np.zeros((4,4), dtype=int) #rows = MPRAGE cols = MPF
for i in range(4): # 0=ignore 1=WM 2=GM 3=CSF
	for j in range(4):
		confusion[i,j] = np.sum((class1 == i) & (class2 == j))

labels = ['ignore/other', 'WM', 'GM', 'CSF']
confusion_df = pd.DataFrame(confusion, index=[f"MPRAGE-{l}" for l in labels],
					columns=[f"MPF-{l}" for l in labels])
print(confusion_df)
