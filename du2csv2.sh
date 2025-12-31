#!/bin/bash
# Copyright Mat X 2025 - All Rights Reserved

# Check if both path arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Please provide two paths as arguments"
    echo "Usage: $0 <path1> <path2>"
    exit 1
fi

path1=$1
path2=$2

# Create temporary files for each path
volume_name1=$(echo "$path1" | awk -F"/Volumes/" '{print $2}' | cut -d'/' -f1)
volume_name2=$(echo "$path2" | awk -F"/Volumes/" '{print $2}' | cut -d'/' -f1)
date_str=$(date +"%Y%m%d")
temp_file1=/tmp/temp1_${date_str}.csv
temp_file2=/tmp/temp2_${date_str}.csv
output_file=/tmp/comparison_${volume_name1}_vs_${volume_name2}_${date_str}.csv

# Generate CSVs for both paths
echo "size,path" > "$temp_file1"
echo "size,path" > "$temp_file2"
du -d 2 -g "$path1" | awk -F"/" '{print $1 "," "\""$(NF-1)"/"$NF"\""}' >> "$temp_file1"
du -d 2 -g "$path2" | awk -F"/" '{print $1 "," "\""$(NF-1)"/"$NF"\""}' >> "$temp_file2"

# Combine the files with headers for each source
echo "path,size_${volume_name1},size_${volume_name2}" > "$output_file"
join -t, -a1 -a2 -o '2.2,1.1,2.1' -e "0" \
    <(tail -n +2 "$temp_file1" | sort -t, -k2) \
    <(tail -n +2 "$temp_file2" | sort -t, -k2) \
    | awk -F, '{print $1","$2","$3}' >> "$output_file"

# Clean up temp files
rm "$temp_file1" "$temp_file2"

open "$output_file"