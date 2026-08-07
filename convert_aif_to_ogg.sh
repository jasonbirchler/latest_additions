#!/bin/bash

usage() {
    echo "Usage: $(basename "$0") [-v] <directory>"
    echo "  -v   Verbose output"
    exit 1
}

VERBOSE=0
DIR=""

while getopts ":v" opt; do
    case $opt in
        v) VERBOSE=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    usage
fi

DIR="$1"

if [ ! -d "$DIR" ]; then
    echo "Error: '$DIR' is not a directory" >&2
    exit 1
fi

while IFS= read -r -d '' aif_file; do
    if [ "$VERBOSE" -eq 1 ]; then
        echo "Found: $aif_file"
    fi

    if [ ! -f "$aif_file" ]; then
        echo "Error: File not found: $aif_file" >&2
        continue
    fi

    base="${aif_file%.*}"
    ogg_file="${base}.ogg"

    if ffmpeg -i "$aif_file" -vn -ar 44100 -strict -2 -c:a vorbis -q:a 5 "$ogg_file" -y; then
        if [ "$VERBOSE" -eq 1 ]; then
            echo "Success: $aif_file -> $ogg_file"
        fi
        rm -f "$aif_file"
    else
        echo "Failed: $aif_file" >&2
    fi
done < <(find "$DIR" -type f \( -iname "*.aiff" -o -iname "*.aif" \) -print0)
