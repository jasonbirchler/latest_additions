#!/bin/bash

usage() {
    echo "Usage: $(basename "$0") [-v] [-i input_format] [-o output_format] <directory>"
    echo "  -i   Input audio format to search for (default: aif)"
    echo "  -o   Output audio format to convert to (default: ogg)"
    echo "  -v   Verbose output"
    exit 1
}

VERBOSE=0
INPUT_FMT="aif"
OUTPUT_FMT="ogg"
DIR=""

while getopts ":vi:o:" opt; do
    case $opt in
        v) VERBOSE=1 ;;
        i) INPUT_FMT="$OPTARG" ;;
        o) OUTPUT_FMT="$OPTARG" ;;
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

INPUT_FMT_LOWER=$(echo "$INPUT_FMT" | tr '[:upper:]' '[:lower:]')
OUTPUT_FMT_LOWER=$(echo "$OUTPUT_FMT" | tr '[:upper:]' '[:lower:]')

case "$OUTPUT_FMT_LOWER" in
    ogg)  CODEC="vorbis"; QUALITY="-q:a 5" ;;
    mp3)  CODEC="libmp3lame"; QUALITY="-q:a 5" ;;
    wav)  CODEC="pcm_s16le"; QUALITY="" ;;
    flac) CODEC="flac"; QUALITY="" ;;
    m4a|aac) CODEC="aac"; QUALITY="-q:a 5" ;;
    opus) CODEC="libopus"; QUALITY="-q:a 5" ;;
    *)    CODEC="$OUTPUT_FMT_LOWER"; QUALITY="" ;;
esac

if [ "$INPUT_FMT_LOWER" = "aif" ]; then
    find_args=(\( -iname "*.aif" -o -iname "*.aiff" \))
else
    find_args=(-iname "*.${INPUT_FMT_LOWER}")
fi

while IFS= read -r -d '' input_file; do
    if [ "$VERBOSE" -eq 1 ]; then
        echo "Found: $input_file"
    fi

    if [ ! -f "$input_file" ]; then
        echo "Error: File not found: $input_file" >&2
        continue
    fi

    base="${input_file%.*}"
    output_file="${base}.${OUTPUT_FMT_LOWER}"

    if ffmpeg -i "$input_file" -vn -ar 44100 -strict -2 -c:a "$CODEC" $QUALITY "$output_file" -y; then
        if [ "$VERBOSE" -eq 1 ]; then
            echo "Success: $input_file -> $output_file"
        fi
        rm -f "$input_file"
    else
        echo "Failed: $input_file" >&2
    fi
done < <(find "$DIR" -type f "${find_args[@]}" -print0)
