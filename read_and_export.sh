#!/bin/bash

# Usage: ./read_and_export.sh [input_directory] [output_file]
# This script reads all text files in the specified directory (and its subdirectories),
# and exports their content to a single output file. It skips binary files and the output file itself.
# Using the output file you can load into an Ai chat for review.

# Set default values if not provided
INPUT_DIR="${1:-.}"  # Default is current directory
OUTPUT_FILE="${2:-exported_content.txt}"  # Default output filename

# Get absolute path of output file
OUTPUT_FILE_ABS=$(readlink -f "$OUTPUT_FILE" 2>/dev/null || echo "$(pwd)/$OUTPUT_FILE")

# Create or clear the output file
> "$OUTPUT_FILE"

# Counter for processed files
count=0

echo "Searching for text files in $INPUT_DIR..."
echo "Output file: $OUTPUT_FILE_ABS"

# First, count total text files (excluding the output file)
total_files=$(find "$INPUT_DIR" -type f | while read -r file; do
    file_abs=$(readlink -f "$file" 2>/dev/null || echo "$(pwd)/$file")
    
    # Skip the output file
    if [ "$file_abs" = "$OUTPUT_FILE_ABS" ]; then
        continue
    fi
    
    if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
        echo "$file"
    fi
done | wc -l)

echo "Found $total_files text files to process (excluding output file)"
echo "----------------------------------------"

# Find all files and process them
find "$INPUT_DIR" -type f | while read -r file; do
    file_abs=$(readlink -f "$file" 2>/dev/null || echo "$(pwd)/$file")
    
    # Skip the output file
    if [ "$file_abs" = "$OUTPUT_FILE_ABS" ]; then
        continue
    fi
    
    # Skip binary files
    if file "$file" | grep -q "text\|ASCII\|UTF-8"; then
        ((count++))
        
        # Show progress with shortened file path
        relative_path="${file#$INPUT_DIR/}"
        echo "[$count/$total_files] Processing: $relative_path"
        
        # Add file header
        echo "=== File: $file ===" >> "$OUTPUT_FILE"
        
        # Add file content
        cat "$file" >> "$OUTPUT_FILE"
        
        # Add separator
        echo -e "\n\n" >> "$OUTPUT_FILE"
    fi
done

echo "----------------------------------------"
echo "✅ Completed! Exported content from $count text files to $OUTPUT_FILE"
echo "Output file size: $(du -sh "$OUTPUT_FILE" | cut -f1)"