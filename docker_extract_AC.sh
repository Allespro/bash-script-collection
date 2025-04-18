#!/bin/bash

# Script for copying modified files from Docker container with directory filtering
# usage: ./extract_changes.sh <container_id> [<target_directory>]

set -euo pipefail

if [ -z "$1" ]; then
    echo "Usage: $0 <container_id> [<target_directory>]"
    exit 1
fi

CONTAINER_ID="$1"
TARGET_DIR="${2:-/}" # root default
OUTPUT_DIR="./output"

echo "Analyzing changes in $TARGET_DIR..."

changes=$(docker diff "$CONTAINER_ID" | grep -E "^[AC]\s${TARGET_DIR}" | awk '{print $2}')

if [ -z "$changes" ]; then
    echo "No changed found."
    exit 0
fi

echo "Found changes:"
echo "$changes" | sed 's/^/  /'

echo "Copying files to $OUTPUT_DIR..."
mkdir -p "$OUTPUT_DIR"

while IFS= read -r file; do
    # file check (not dir)
    if docker exec "$CONTAINER_ID" test -f "$file"; then
        dest="$OUTPUT_DIR$file"
        mkdir -p "$(dirname "$dest")"
        echo "  → $file"
        docker cp "$CONTAINER_ID:$file" "$dest"
    else
        echo "  Directory skipping: $file"
    fi
done <<< "$changes"

echo "The modified files are copied to $OUTPUT_DIR."
