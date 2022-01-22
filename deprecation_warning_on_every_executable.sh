#!/bin/bash
if [ ! -e /.dockerenv ]; then
  echo -n "Refusing to run outside of a Docker container as this would've"\
  "messed up your system. You're welcome." 1>&2
  exit 1
fi

mkdir /actual_executables

echo "disarmed while replacing executables" > /tmp/printed_deprecation

find / -type f -executable -writable -readable \
  \( '!' \( -name "*.so" -or -path "$PWD/*" -or -path "/actual_executables/*" \) \) \
  -print0 > executable_list
cat executable_list | xargs -0 -I '{}' ./replace_executable.sh '{}'
rm -f /tmp/printed_deprecation
