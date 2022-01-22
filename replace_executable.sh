#!/bin/bash

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
if [ ! -e /tmp/printed_deprecation ]; then
  echo "WARNING: You are using a DEPRECATED Docker image that is not being"\\
    "updated with security patches." 1>&2
  echo "See https://github.com/smheidrich/docker-debian-git-sshd for more"\\
    "information." 1>&2
  echo done > /tmp/printed_deprecation
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
