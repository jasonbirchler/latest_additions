#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [-t N] [-v] <directory> [output_file]" >&2
    exit 1
}

input_dir=""
output_file=""
top_n=""
verbose=0

log() {
    if [ "$verbose" -eq 1 ]; then
        echo "[LOG] $*" >&2
    fi
}

while getopts ":t:v" opt; do
    case $opt in
        t)
            top_n="$OPTARG"
            ;;
        v)
            verbose=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            usage
            ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -lt 1 ]; then
    usage
fi

input_dir="$1"
output_file="${2:-${input_dir%/}/directories_by_date.txt}"

if [ ! -d "$input_dir" ]; then
    echo "Error: '$input_dir' is not a directory" >&2
    exit 1
fi

log "Input directory: $input_dir"
log "Output file:     $output_file"
log "Top N:           ${top_n:-all}"

prefix="${input_dir%/}/"

get_stat_lines() {
    if stat --version >/dev/null 2>&1; then
        find "$1" -mindepth 1 -maxdepth 1 -type d -exec stat -c '%Y %n' {} +
    else
        find "$1" -mindepth 1 -maxdepth 1 -type d -exec stat -f '%m %N' {} +
    fi
}

log "Getting stat lines for '$input_dir'"
overall_lines=$(get_stat_lines "$input_dir" | awk '$1 > 0') || {
    log "ERROR: get_stat_lines failed for '$input_dir'"
    exit 1
}
log "Got $(echo "$overall_lines" | wc -l | tr -d ' ') lines from stat"

log "Sorting directories"
sorted_top_dirs=$(printf '%s\n' "$overall_lines" | sort -rn) || {
    log "ERROR: sort failed"
    exit 1
}
log "Sorted top dirs: $(echo "$sorted_top_dirs" | wc -l | tr -d ' ') entries"

log "Scanning top-level directories in '$input_dir'"

if [ -n "$top_n" ]; then
    log "Applying top N limit: $top_n"
    sorted_top_dirs=$(printf '%s\n' "$sorted_top_dirs" | awk -v n="$top_n" 'NR<=n') || {
        log "ERROR: awk limit failed"
        exit 1
    }
    log "Limited to top $top_n directories"
fi

log "Starting output block"
{
    if [ -n "$sorted_top_dirs" ] && [ "$(echo "$sorted_top_dirs" | tr -d '[:space:]')" != "" ]; then
        log "Processing $(echo "$sorted_top_dirs" | wc -l | tr -d ' ') directories"
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            dir_path=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
            dir_name=$(echo "$dir_path" | awk -v p="$prefix" '{sub("^" p, "", $0); print}')

            log "Processing directory: $dir_name"
            echo "- $dir_name"

            if [ -d "$dir_path" ]; then
                log "Scanning subdirectories of: $dir_name"
                sub_lines=$(get_stat_lines "$dir_path")
                if [ -n "$sub_lines" ]; then
                    printf '%s\n' "$sub_lines" | sort -rn | while IFS= read -r subline; do
                        sub_path=$(echo "$subline" | awk '{$1=""; print substr($0,2)}')
                        sub_name=$(echo "$sub_path" | awk -v p="${dir_path%/}/" '{sub("^" p, "", $0); print}')
                        echo "  - $sub_name"
                    done
                fi
            fi
        done <<< "$sorted_top_dirs"
    else
        log "No directories found to process"
    fi
} > "$output_file" || {
    log "ERROR: Failed to write to output file '$output_file'"
    exit 1
}

log "Output written to $output_file"
if [ -f "$output_file" ]; then
    wc -l < "$output_file" | xargs -I{} echo "Wrote {} lines to $output_file"
else
    log "ERROR: Output file was not created"
    exit 1
fi
