
import nibabel as nib

ref_img = nib.load("MPRAGE.nii")

img = nib.load("mprage1_flipped.nii.gz")

data = img.get_fdata()
affine = img.affine

hdr = img.header.copy()
hdr.set_zooms(ref_img.header.get_zooms())

fixed_filename = 'mprage1_flipped_fixed.nii.gz'
fixed_img  = nib.Nifti1Image(data, affine, header=hdr)
nib.save(fixed_img, fixed_filename)

print(f'Voxels sizes copied. Saved fixed image as {fixed_filename}')
