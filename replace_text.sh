#!/bin/bash
# Bash script that recursively finds and replaces text in all files within a selected directory
usage() {
  echo "Usage: $0 [directory] [old_text] [new_text]"
  exit 1
}

if [ "$#" -ne 3 ]; then
  usage
fi

directory=$1
old_text=$2
new_text=$3

if [ ! -d "$directory" ]; then
  echo "Error: Directory $directory does not exist."
  exit 1
fi

find "$directory" -type f -exec sed -i "s/$old_text/$new_text/g" {} +

echo "Replacement complete."
