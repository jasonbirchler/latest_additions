#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 [-t N] <directory> [output_file]" >&2
    exit 1
}

input_dir=""
output_file=""
top_n=""

while getopts ":t:" opt; do
    case $opt in
        t)
            top_n="$OPTARG"
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

prefix="${input_dir%/}/"

get_stat_lines() {
    if stat --version >/dev/null 2>&1; then
        find "$1" -mindepth 1 -maxdepth 1 -type d -exec stat -c '%Y %n' {} +
    else
        find "$1" -mindepth 1 -maxdepth 1 -type d -exec stat -f '%m %N' {} +
    fi
}

overall_lines=$(get_stat_lines "$input_dir" | awk '$1 > 0')
sorted_top_dirs=$(printf '%s\n' "$overall_lines" | sort -rn)

if [ -n "$top_n" ]; then
    sorted_top_dirs=$(printf '%s\n' "$sorted_top_dirs" | head -n "$top_n")
fi

{
    if [ -n "$sorted_top_dirs" ]; then
        while IFS= read -r line; do
            dir_path=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
            dir_name=$(echo "$dir_path" | awk -v p="$prefix" '{sub("^" p, "", $0); print}')

            echo "- $dir_name"

            if [ -d "$dir_path" ]; then
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
    fi
} > "$output_file"

wc -l < "$output_file" | xargs -I{} echo "Wrote {} lines to $output_file"
