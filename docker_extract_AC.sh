#!/bin/bash

# Script for copying modified files from Docker container with directory filtering
# usage: ./extract_changes.sh <container_id> [<target_directory>]

if [ -z "$1" ]; then
    echo "Usage: $0 <container_id> [<target_directory>]"
    exit 1
fi

CONTAINER_ID=$1
TARGET_DIR=${2:-/}  # root default

OUTPUT_DIR="./output${TARGET_DIR}"

changes=$(docker diff "$CONTAINER_ID" | grep -E "^[AC]\s${TARGET_DIR}/.*" | awk '{print $2}')

if [ -z "$changes" ]; then
    echo "No changes found in $TARGET_DIR"
    exit 0
fi

echo "Copying changes from $TARGET_DIR:"
mkdir -p "$OUTPUT_DIR"

for file in $changes; do
    dest="./output$file"
    mkdir -p "$(dirname "$dest")"
    echo "  -> $file"
    docker cp "$CONTAINER_ID:$file" "$dest"
done

echo "Files copied to $OUTPUT_DIR"
