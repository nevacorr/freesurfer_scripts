#!/bin/bash

while read -r subject; do
	./make_lobe_masks.sh "$subject"
done < subjects_list.txt
