#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
engine=${GODOT:-godot}
xdg=$(mktemp -d "${TMPDIR:-/tmp}/ak-studio-xdg.XXXXXX")
trap 'rm -rf -- "$xdg"' EXIT
export XDG_CACHE_HOME="$xdg/cache"
export XDG_CONFIG_HOME="$xdg/config"
export XDG_DATA_HOME="$xdg/data"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
"$engine" --headless --path "$here" --import
case "${1:-}" in
  --check) "$engine" --headless --path "$here" -- --check ;;
  --capture)
    test "$#" -eq 2 || { echo "Usage: $0 --capture /absolute/output.png" >&2; exit 2; }
    case "$2" in /*.png) ;; *) echo 'Provide an absolute .png path' >&2; exit 2;; esac
    "$engine" --path "$here" --resolution 1440x900 -- --capture "$2" ;;
  "") "$engine" --path "$here" --resolution 1440x900 ;;
  *) echo "Usage: $0 [--check | --capture /absolute/output.png]" >&2; exit 2 ;;
esac
