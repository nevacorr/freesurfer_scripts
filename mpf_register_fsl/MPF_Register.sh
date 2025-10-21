#!/bin/bash

# Base directory containing all subject folders
base_dir="./SEG_REPRO"

# Only process these subjects for now
process_subjects=("H08-1" "H15-1")

# Loop through each subject folder in SEG_REPRO
for subj_dir in ${base_dir}/H*; do

    subj_name=$(basename "$subj_dir")

    # Skip if subject is not in allowed list
    if [[ ! " ${process_subjects[@]} " =~ " ${subj_name} " ]]; then
	echo "Skipping ${subj_name}..."
	continue
    fi		

    echo "Processing subject folder: ${subj_dir}"

    # Locate input files
    # Try standard names first, fall back to alternate names
    if [[ -f "${subj_dir}/VFA1.hdr" ]]; then
	VFA1="${subj_dir}/VFA1.hdr"
	VFA2="${subj_dir}/VFA2.hdr"
	MT="${subj_dir}/MT1.hdr"
	echo "  Using standard file names"
    else
	VFA1="${subj_dir}/VFA1r.hdr"
	VFA2="${subj_dir}/VFA2r.hdr"
	MT="${subj_dir}/MT1r.hdr"
	echo "  Using alternate file names"
    fi

    # Define output files (without extension for mcflirt)
    VFA1reg="${subj_dir}/VFA1reg"
    VFA2reg="${subj_dir}/VFA2reg"
    MT1reg="${subj_dir}/MT1reg"

    # Check if registration is already done (any one registered file present)
    if [[ -f "${VFA1reg}.hdr" && -f "${VFA2reg}.hdr" && -f "${MT1reg}.hdr" ]]; then
        echo "  Registered files already exist - skipping ${subj_dir}."
        echo
        continue
    fi

    # Make sure input files exist
    if [[ ! -f "$VFA1" || ! -f "$VFA2" || ! -f "$MT" ]]; then
        echo "  Missing one or more input files in ${subj_dir}, skipping..."
        echo
        continue
    fi

    echo "  Registering images to VFA1..."

    # Register VFA2 to VFA1
    mcflirt -in "$VFA2" -out "$VFA2reg" -reffile "$VFA1" 

    # Register MT to VFA1
    mcflirt -in "$MT" -out "$MT1reg" -reffile "$VFA1" 

    # Copy VFA1 to new name 
    for ext in hdr img; do
    	cp "${VFA1%.*}.${ext}" "${VFA1reg}.${ext}"
    done

    echo "  Converting registered images to ANALYZE format..."
    fslchfiletype ANALYZE "$VFA2reg"
    fslchfiletype ANALYZE "$MT1reg"

    echo "  Cleaning up temporary NIFTI files..."
    rm -f "${subj_dir}"/*.nii.gz

    echo "  Done with ${subj_dir}."
    echo
done

echo "All registrations complete!"
