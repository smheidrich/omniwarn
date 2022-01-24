#!/bin/bash
pkgdir="$PWD"
tmpdir="$(mktemp -d)"

pushd "$tmpdir"

cp -r "$pkgdir"/* .

cat > warning <<HEREDOC
Hello, this is a warning.
HEREDOC

cat > Dockerfile <<HEREDOC
FROM debian:11

ARG DEBIAN_FRONTEND=noninteractive

COPY ./omniwarn warning ./

RUN ./omniwarn replace-all
HEREDOC

docker build . | tee build-log.txt

grep -iE '(error|warning)' build-log.txt \
  && { echo "Errors or warnings detected, see above. Test failed."; exit 1; }
