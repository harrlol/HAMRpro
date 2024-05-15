#!/bin/bash

# Function to merge two BAM files using samtools
merge_files() {
    local file1=$1
    local file2=$2
    local output_file=$3
    samtools merge -f "$output_file" "$file1" "$file2"
}

# Function to recursively merge a list of BAM files
merge_file_list() {
    local files=("$@")
    local num_files=${#files[@]}

    if [[ $num_files -eq 1 ]]; then
        mv "${files[0]}" merged_output.bam
        return
    fi

    local temp_files=()
    local i=0

    while [[ $i -lt $num_files ]]; do
        if [[ $((i + 1)) -lt $num_files ]]; then
            local temp_output="temp_$((i/2)).bam"
            merge_files "${files[i]}" "${files[i + 1]}" "$temp_output"
            temp_files+=("$temp_output")
        else
            temp_files+=("${files[i]}")
        fi
        ((i += 2))
    done

    merge_file_list "${temp_files[@]}"
}

# Generate list of input files
input_files=()
for number in {0..2355}; do
    input_files+=("FAW63849_pass_d29e9da2_a21576d9_${number}.bam")
done

# Merge the files
merge_file_list "${input_files[@]}"
