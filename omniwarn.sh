#!/bin/bash

print_commands() {
  cat <<HEREDOC
replace     - Replace single executable with a warning-printing wrapper
replace-all - Replace (almost) all executables on the system
revert-all  - Undo all replacements
HEREDOC
}

print_help() {
  cat <<HEREDOC
Usage: $(basename "$0") <command> [arguments...]

Extreme hackjob to make a Docker image print warnings with (almost) any use.

Meant for deprecation warnings in images that are so old nobody should be using
them anymore but are getting downloads anyway. DON'T USE on images that are
actually important.

Works by replacing almost every single executable in the image with a wrapper
that prints a warning, then executes the original executable.

Commands:

HEREDOC
  print_commands
}


ensure_in_docker() {
  if [ ! -e /.dockerenv ]; then
    echo -n "Refusing to run outside of a Docker container as this would've"\
    "messed up your system. You're welcome." 1>&2
    exit 1
  fi
}


replace_all() {
  # disarm
  echo "disarmed while replacing executables" > /tmp/printed_warning

  find / -type f -executable -writable -readable \
    \( '!' \( \
      -name "*.so" -or -path "$PWD/*" -or -path "/actual_executables/*" \
    \) \) \
    -print0 > executable_list

  cat executable_list | xargs -0 -I '{}' "$0" replace '{}'

  # re-arm
  rm -f /tmp/printed_warning
}


replace() {
  mkdir -p /actual_executables

  # we'll put all executables in their own folders so we can add the folder of
  # the current program to PATH and have it remain usable from within this script
  # while it is being moved (currently only important for mv)
  actual_dir="$(mktemp -dp /actual_executables)"
  actual="$actual_dir/$(basename "$1")"
  export PATH="$actual_dir":"$PATH"

  # put some metadata into that folder to make reverting easier
  echo -n "$1" > "$actual_dir"/original_path

  # replacing bash needs special handling so the shebang of our wrapper doesn't
  # lead to infinite recursion
  shebang_path="/bin/bash"
  if [ "$1" = "$shebang_path" ]; then
    shebang_path="$actual"
  fi

  # write script to tmp file for atomic replace
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<HEREDOC
#!$shebang_path
# print warning
if [ ! -e /tmp/printed_warning ]; then
  echo "WARNING: You are using a DEPRECATED Docker image that is not being"\\
    "updated with security patches." 1>&2
  echo "See https://github.com/smheidrich/docker-debian-git-sshd for more"\\
    "information." 1>&2
  echo done > /tmp/printed_warning
fi
# run desired program
"$actual" "\$@"
HEREDOC

  # copy permissions and ownership
  chmod --reference="$1" "$tmpfile"
  chown --reference="$1" "$tmpfile"

  # replace
  echo "$1 -> $actual"
  mv "$1" "$actual"
  hash -r # reset program lookup cache so PATH hack from above works for this mv
  mv "$tmpfile" "$1"
}


revert_all() {
  for dir in /actual_executables/*; do
    original_path="$(cat "$dir"/original_path)"
    executable_name="$(basename "$original_path")"
    original_file="$dir"/"$executable_name"
    echo "$original_file -> $original_path"
    mv "$original_file" "$original_path"
  done
}

# CLI
cmd=$1
shift

case $cmd in
    "" | "-h" | "--help")
      print_help
      ;;
    replace)
      replace "$@"
      ;;
    replace-all)
      ensure_in_docker
      replace_all "$@"
      ;;
    revert-all)
      ensure_in_docker
      revert_all "$@"
      ;;
    *)
      echo "Error: Invalid command '$cmd'. Valid commands are:"
      echo
      print_commands
      exit 1
esac
