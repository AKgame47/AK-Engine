#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/ak-shader-preview.XXXXXX")
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

check=false
if [ "$#" -eq 1 ] && [ "$1" = "--check" ]; then
    check=true
elif [ "$#" -gt 0 ]; then
    if [ "$#" -ne 2 ] || [ "$1" != "--capture" ]; then
        printf 'Usage: %s [--check | --capture /absolute/output.png]\n' "$0" >&2
        exit 2
    fi
    case "$2" in
        /*.png) ;;
        *) printf 'Capture output must be an absolute .png path.\n' >&2; exit 2 ;;
    esac
fi
cp "$here"/preview/project.godot "$here"/preview/preview.tscn "$here"/preview/preview.gd "$work"/
cp -R "$here/../assets/samples/preview/." "$work/"
mkdir -p "$work/shaders"
cp "$here"/water.gdshader "$here"/sky.gdshader "$here"/foliage.gdshader "$work/shaders/"
export XDG_CACHE_HOME="$work/.xdg/cache"
export XDG_CONFIG_HOME="$work/.xdg/config"
export XDG_DATA_HOME="$work/.xdg/data"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
"${GODOT:-godot}" --headless --path "$work" --import
if [ "$check" = true ]; then
    "${GODOT:-godot}" --headless --path "$work" --quit-after 8
else
    "${GODOT:-godot}" --path "$work" -- "$@"
fi
