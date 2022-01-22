#!/bin/bash
if [ ! -e /.dockerenv ]; then
  echo -n "Refusing to run outside of a Docker container as this would've"\
  "messed up your system. You're welcome." 1>&2
  exit 1
fi

for dir in /actual_executables/*; do
  original_path="$(cat "$dir"/original_path)"
  executable_name="$(basename "$original_path")"
  original_file="$dir"/"$executable_name"
  echo "$original_file -> $original_path"
  mv "$original_file" "$original_path"
done
