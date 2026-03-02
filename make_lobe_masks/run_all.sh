#!/bin/bash

# Usage: bash run_all.sh

while read -r subject; do
	./make_lobe_masks.sh "$subject"
#done < subjects_list_MPFregtoPD.txt
done < subjects_list.txt
