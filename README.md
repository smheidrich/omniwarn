# omniwarn.sh

Tool for making all executables in a Docker image print a warning when run.

Meant to be used for deprecation warnings on no longer maintained images.

## Installation

Everything is contained in a single script, so just download that into the
directory with your `Dockerfile` and make it executable:

```bash
curl -L "https://raw.githubusercontent.com/smheidrich/omniwarn/main/omniwarn.sh" -o omniwarn.sh
chmod +x omniwarn.sh
```

## Usage

Help text:

```
$ ./omniwarn.sh -h
Usage: omniwarn.sh <command> [arguments...]

Extreme hackjob to make a Docker image print warnings with (almost) any use.

Meant for deprecation warnings in images that are so old nobody should be using
them anymore but are getting downloads anyway. DON'T USE on images that are
actually important.

Works by replacing almost every single executable in the image with a wrapper
that prints a warning, then executes the original executable.

Example usage in Dockerfile, after writing your desired warning message into a
file named "warning":

  COPY omniwarn.sh warning ./
  RUN ./omniwarn.sh replace-all

Putting this at the end of your Dockerfile will build an image that prints your
warning message to stderr the first time any program is launched.


Commands:

replace-all - Replace (almost) all executables on the system
revert-all  - Undo all replacements
```

## License

MIT License, see LICENSE.md
