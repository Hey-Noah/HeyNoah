#!/bin/bash

# Set the output file name
output_file="AllSwiftClasses.txt"

# Find all .swift files in the current directory and subdirectories
# Concatenate them into the output file
find . -name "*.swift" -type f -exec cat {} + > "$output_file"

echo "All .swift files have been concatenated into $output_file"

