#!/bin/bash
echo "Begin test: $0"
pkgdir="$PWD"
tmpdir="$(mktemp -d)"

pushd "$tmpdir"

cp -r "$pkgdir"/* .


# prepare stuff for building Docker image

cat > warning <<HEREDOC
Hello, this is a warning.
HEREDOC

cat > Dockerfile <<HEREDOC
FROM debian:11

ARG DEBIAN_FRONTEND=noninteractive

COPY ./omniwarn warning ./

RUN ./omniwarn replace-all
HEREDOC


# build Docker image

docker build . | tee build-log.txt

docker_rc="$?"

error_lines="$(grep -iE '(error)' build-log.txt)"
if [ -n "$error_lines" ]; then
  echo "Errors detected during build:" 2>&1
  echo "----------------" 2>&1
  echo "$error_lines" 2>&1
  echo "----------------" 2>&1
fi

if [ "$docker_rc" != 0 -o -n "$error_lines" ]; then
  echo "Build failed." 2>&1
  exit 1
fi

docker_image="$(grep 'Successfully built' build-log.txt | awk '{ print $3 }')"


# run Docker image

echo "Running built image $docker_image."

docker run "$docker_image" | tee run-log.txt

docker_rc="$?"

error_lines="$(grep -iE '(error)' run-log.txt)"
if [ -n "$error_lines" ]; then
  echo "Errors detected during run:" 2>&1
  echo "----------------" 2>&1
  echo "$error_lines" 2>&1
  echo "----------------" 2>&1
fi

grep -q "Hello, this is a warning." run-log.txt

grep_rc="$?"

if [ "$grep_rc" != 0 ]; then
  echo "Docker container did not print desired warning." 2>&1
fi

if [ "$docker_rc" != 0 -o "$grep_rc" != 0 ]; then
  echo "Test failed." 2>&1
  exit 1
fi

echo "End test: $0"
