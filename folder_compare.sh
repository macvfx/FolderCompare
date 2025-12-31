#!/bin/bash
# Copyright Mat X 2025 - All Rights Reserved
# Enhanced Folder Comparison Tool
# Compares two folder structures for size, file counts, and file type distributions

set -euo pipefail

# Default values
DEPTH=2
FILE_TYPES=()
LOG_FILE=""
OUTPUT_DIR="/tmp"
CASE_INSENSITIVE=false
VERBOSE=false
SHOW_DIFFERENCES_ONLY=false
DEEP_SCAN=false
DEEP_SCAN_DEPTH=0
EXCLUDE_PATTERNS=()
# Always exclude .DS_Store files
ALWAYS_EXCLUDE=(".DS_Store")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <path1> <path2>

Compare two folders for size, structure, and file type distribution.

OPTIONS:
    -d, --depth DEPTH           Depth of subdirectory comparison (default: 2)
    -t, --types TYPE1,TYPE2     Comma-separated file types to count (e.g., mxf,mov,mp4)
    -i, --ignore-case           Case-insensitive file type matching
    -l, --log FILE              Log file path (default: /tmp/folder_compare_YYYYMMDD_HHMMSS.log)
    -o, --output-dir DIR        Output directory for CSV files (default: /tmp)
    -v, --verbose               Verbose output
    --diff-only                 Show only differences in output
    --deep DEPTH                Deep scan: list all subfolders to specified depth with size & file count
    -x, --exclude PATTERNS      Comma-separated patterns to exclude (e.g., .git,Thumbs.db,*.tmp)
                                Note: .DS_Store is always excluded
    -h, --help                  Display this help message

EXAMPLES:
    # Basic comparison with default depth
    $0 /Volumes/Source/Project /Volumes/Backup/Project

    # Compare with depth 3 and track specific file types
    $0 -d 3 -t mxf,mov,mp4 /path/to/folder1 /path/to/folder2

    # Case-insensitive file type matching with logging
    $0 -i -t MXF,mov -l comparison.log /path1 /path2

    # Show only differences with verbose output
    $0 --diff-only -v /path1 /path2

    # Deep scan with detailed subfolder listing
    $0 --deep 5 -t mxf,mov /path1 /path2

    # Exclude specific patterns (.DS_Store always excluded)
    $0 -x ".git,Thumbs.db,*.tmp" /path1 /path2

EOF
    exit 0
}

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi

    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ]; then
        case $level in
            ERROR)   echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
            WARNING) echo -e "${YELLOW}[WARNING]${NC} $message" ;;
            INFO)    echo -e "${GREEN}[INFO]${NC} $message" ;;
            DEBUG)   echo -e "${BLUE}[DEBUG]${NC} $message" ;;
        esac
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--depth)
                DEPTH="$2"
                shift 2
                ;;
            -t|--types)
                IFS=',' read -ra FILE_TYPES <<< "$2"
                shift 2
                ;;
            -i|--ignore-case)
                CASE_INSENSITIVE=true
                shift
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -o|--output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --diff-only)
                SHOW_DIFFERENCES_ONLY=true
                shift
                ;;
            --deep)
                DEEP_SCAN=true
                DEEP_SCAN_DEPTH="$2"
                shift 2
                ;;
            -x|--exclude)
                IFS=',' read -ra EXCLUDE_PATTERNS <<< "$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            -*)
                echo "Error: Unknown option: $1"
                usage
                ;;
            *)
                if [ -z "${PATH1:-}" ]; then
                    PATH1="$1"
                elif [ -z "${PATH2:-}" ]; then
                    PATH2="$1"
                else
                    echo "Error: Too many arguments"
                    usage
                fi
                shift
                ;;
        esac
    done
}

# Validate inputs
validate_inputs() {
    if [ -z "${PATH1:-}" ] || [ -z "${PATH2:-}" ]; then
        echo "Error: Please provide two paths as arguments"
        usage
    fi

    if [ ! -d "$PATH1" ]; then
        log ERROR "Path does not exist or is not a directory: $PATH1"
        exit 1
    fi

    if [ ! -d "$PATH2" ]; then
        log ERROR "Path does not exist or is not a directory: $PATH2"
        exit 1
    fi

    if ! [[ "$DEPTH" =~ ^[0-9]+$ ]] || [ "$DEPTH" -lt 1 ]; then
        log ERROR "Depth must be a positive integer"
        exit 1
    fi

    if [ ! -d "$OUTPUT_DIR" ]; then
        log ERROR "Output directory does not exist: $OUTPUT_DIR"
        exit 1
    fi
}

# Convert bytes to human-readable format
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f", b/1024}')KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f", b/1048576}')MB"
    else
        echo "$(awk -v b="$bytes" 'BEGIN {printf "%.2f", b/1073741824}')GB"
    fi
}

# Get folder name from path
get_folder_name() {
    basename "$1"
}

# Build find exclude arguments
build_find_excludes() {
    local parts=()

    # Add always excluded patterns
    if [ ${#ALWAYS_EXCLUDE[@]} -gt 0 ]; then
        for pattern in "${ALWAYS_EXCLUDE[@]}"; do
            parts+=("$pattern")
        done
    fi

    # Add user-specified exclude patterns
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            parts+=("$pattern")
        done
    fi

    # Build the find expression
    if [ ${#parts[@]} -gt 0 ]; then
        local result="-not \\("
        local first=true
        for pattern in "${parts[@]}"; do
            if [ "$first" = true ]; then
                result="$result -name \"$pattern\""
                first=false
            else
                result="$result -o -name \"$pattern\""
            fi
        done
        result="$result \\)"
        echo "$result"
    fi
}

# Count files by type in a directory
count_files_by_type() {
    local path="$1"
    local ext="$2"
    local count

    # Build exclude args as a string
    local exclude_str=$(build_find_excludes)

    if [ "$CASE_INSENSITIVE" = true ]; then
        if [ -n "$exclude_str" ]; then
            count=$(eval "find \"$path\" -type f $exclude_str -iname \"*.${ext}\" 2>/dev/null" | wc -l | tr -d ' ')
        else
            count=$(find "$path" -type f -iname "*.${ext}" 2>/dev/null | wc -l | tr -d ' ')
        fi
    else
        if [ -n "$exclude_str" ]; then
            count=$(eval "find \"$path\" -type f $exclude_str -name \"*.${ext}\" 2>/dev/null" | wc -l | tr -d ' ')
        else
            count=$(find "$path" -type f -name "*.${ext}" 2>/dev/null | wc -l | tr -d ' ')
        fi
    fi

    echo "$count"
}

# Get total file count
get_file_count() {
    local path="$1"
    local exclude_str=$(build_find_excludes)

    if [ -n "$exclude_str" ]; then
        eval "find \"$path\" -type f $exclude_str 2>/dev/null" | wc -l | tr -d ' '
    else
        find "$path" -type f 2>/dev/null | wc -l | tr -d ' '
    fi
}

# Generate size comparison CSV
generate_size_comparison() {
    local path1="$1"
    local path2="$2"
    local output_file="$3"

    log INFO "Generating size comparison (depth: $DEPTH)..."

    # Create temporary files
    local temp_file1=$(mktemp)
    local temp_file2=$(mktemp)

    # Get folder sizes with specified depth
    log DEBUG "Analyzing $path1..."
    echo "size_bytes,rel_path" > "$temp_file1"
    du -d "$DEPTH" "$path1" 2>/dev/null | while read -r size path; do
        # Convert size to bytes (du on macOS uses 512-byte blocks by default)
        size_bytes=$((size * 512))
        rel_path="${path#$path1}"
        rel_path="${rel_path#/}"
        [ -z "$rel_path" ] && rel_path="."
        echo "$size_bytes,\"$rel_path\"" >> "$temp_file1"
    done

    log DEBUG "Analyzing $path2..."
    echo "size_bytes,rel_path" > "$temp_file2"
    du -d "$DEPTH" "$path2" 2>/dev/null | while read -r size path; do
        size_bytes=$((size * 512))
        rel_path="${path#$path2}"
        rel_path="${rel_path#/}"
        [ -z "$rel_path" ] && rel_path="."
        echo "$size_bytes,\"$rel_path\"" >> "$temp_file2"
    done

    # Get folder names for headers
    local name1=$(get_folder_name "$path1")
    local name2=$(get_folder_name "$path2")

    # Create combined output
    echo "relative_path,size_bytes_${name1},size_human_${name1},size_bytes_${name2},size_human_${name2},difference_bytes,difference_human,percent_diff,status" > "$output_file"

    # Join the files
    join -t, -a1 -a2 -o '0,1.1,2.1' -e "0" \
        <(tail -n +2 "$temp_file1" | sort -t, -k2) \
        <(tail -n +2 "$temp_file2" | sort -t, -k2) \
        | while IFS=, read -r path size1 size2; do
            # Remove quotes from path
            path=$(echo "$path" | tr -d '"')

            # Calculate difference
            diff=$((size2 - size1))

            # Calculate percentage difference
            if [ "$size1" -eq 0 ] && [ "$size2" -eq 0 ]; then
                percent_diff="0.00"
                status="IDENTICAL"
            elif [ "$size1" -eq 0 ]; then
                percent_diff="N/A"
                status="ONLY_IN_${name2}"
            elif [ "$size2" -eq 0 ]; then
                percent_diff="N/A"
                status="ONLY_IN_${name1}"
            else
                percent_diff=$(awk -v d="$diff" -v s="$size1" 'BEGIN {printf "%.2f", (d / s) * 100}')
                if [ "$diff" -eq 0 ]; then
                    status="IDENTICAL"
                elif [ "$diff" -gt 0 ]; then
                    status="LARGER_IN_${name2}"
                else
                    status="LARGER_IN_${name1}"
                fi
            fi

            # Convert to human-readable
            human1=$(bytes_to_human "$size1")
            human2=$(bytes_to_human "$size2")
            human_diff=$(bytes_to_human "${diff#-}")
            [ "$diff" -lt 0 ] && human_diff="-${human_diff}"

            # Apply diff-only filter if requested
            if [ "$SHOW_DIFFERENCES_ONLY" = true ] && [ "$status" = "IDENTICAL" ]; then
                continue
            fi

            echo "\"$path\",$size1,$human1,$size2,$human2,$diff,$human_diff,$percent_diff,$status" >> "$output_file"
        done

    # Clean up
    rm -f "$temp_file1" "$temp_file2"

    log INFO "Size comparison saved to: $output_file"
}

# Generate file type comparison CSV
generate_filetype_comparison() {
    local path1="$1"
    local path2="$2"
    local output_file="$3"

    if [ ${#FILE_TYPES[@]} -eq 0 ]; then
        log INFO "No file types specified, skipping file type comparison"
        return
    fi

    log INFO "Generating file type comparison..."

    local name1=$(get_folder_name "$path1")
    local name2=$(get_folder_name "$path2")

    # Create header
    echo "file_type,count_${name1},count_${name2},total_combined,difference,percent_diff,status" > "$output_file"

    # Track totals
    local total_count1=0
    local total_count2=0

    # Count each file type
    for ext in "${FILE_TYPES[@]}"; do
        log DEBUG "Counting .$ext files..."

        count1=$(count_files_by_type "$path1" "$ext")
        count2=$(count_files_by_type "$path2" "$ext")

        # Add to totals
        total_count1=$((total_count1 + count1))
        total_count2=$((total_count2 + count2))

        diff=$((count2 - count1))
        total_combined=$((count1 + count2))

        # Calculate percentage difference
        if [ "$count1" -eq 0 ] && [ "$count2" -eq 0 ]; then
            percent_diff="0.00"
            status="NONE_FOUND"
        elif [ "$count1" -eq 0 ]; then
            percent_diff="N/A"
            status="ONLY_IN_${name2}"
        else
            percent_diff=$(awk -v d="$diff" -v c="$count1" 'BEGIN {printf "%.2f", (d / c) * 100}')
            if [ "$diff" -eq 0 ]; then
                status="IDENTICAL"
            elif [ "$diff" -gt 0 ]; then
                status="MORE_IN_${name2}"
            else
                status="MORE_IN_${name1}"
            fi
        fi

        # Apply diff-only filter if requested
        if [ "$SHOW_DIFFERENCES_ONLY" = true ] && [ "$status" = "IDENTICAL" ]; then
            continue
        fi

        echo "$ext,$count1,$count2,$total_combined,$diff,$percent_diff,$status" >> "$output_file"
    done

    # Add totals row
    local total_diff=$((total_count2 - total_count1))
    local total_combined=$((total_count1 + total_count2))
    local total_percent_diff
    if [ "$total_count1" -eq 0 ] && [ "$total_count2" -eq 0 ]; then
        total_percent_diff="0.00"
    elif [ "$total_count1" -eq 0 ]; then
        total_percent_diff="N/A"
    else
        total_percent_diff=$(awk -v d="$total_diff" -v c="$total_count1" 'BEGIN {printf "%.2f", (d / c) * 100}')
    fi

    echo "\"--- TOTAL ---\",$total_count1,$total_count2,$total_combined,$total_diff,$total_percent_diff,SUMMARY" >> "$output_file"

    log INFO "File type comparison saved to: $output_file"
    log INFO "Total tracked files in ${name1}: $total_count1"
    log INFO "Total tracked files in ${name2}: $total_count2"
}

# Generate summary report
generate_summary() {
    local path1="$1"
    local path2="$2"
    local output_file="$3"

    log INFO "Generating summary report..."

    local name1=$(get_folder_name "$path1")
    local name2=$(get_folder_name "$path2")

    # Get total sizes
    local total_size1=$(du -sk "$path1" 2>/dev/null | cut -f1)
    local total_size2=$(du -sk "$path2" 2>/dev/null | cut -f1)
    total_size1=$((total_size1 * 1024))
    total_size2=$((total_size2 * 1024))

    # Get file counts
    local file_count1=$(get_file_count "$path1")
    local file_count2=$(get_file_count "$path2")

    # Get directory counts
    local dir_count1=$(find "$path1" -type d 2>/dev/null | wc -l | tr -d ' ')
    local dir_count2=$(find "$path2" -type d 2>/dev/null | wc -l | tr -d ' ')

    # Create summary
    cat > "$output_file" << EOF
metric,${name1},${name2},difference,status
total_size_bytes,$total_size1,$total_size2,$((total_size2 - total_size1)),$([ $total_size1 -eq $total_size2 ] && echo "IDENTICAL" || echo "DIFFERENT")
total_size_human,$(bytes_to_human $total_size1),$(bytes_to_human $total_size2),$(bytes_to_human $((total_size2 - total_size1))),
total_files,$file_count1,$file_count2,$((file_count2 - file_count1)),$([ $file_count1 -eq $file_count2 ] && echo "IDENTICAL" || echo "DIFFERENT")
total_directories,$dir_count1,$dir_count2,$((dir_count2 - dir_count1)),$([ $dir_count1 -eq $dir_count2 ] && echo "IDENTICAL" || echo "DIFFERENT")
EOF

    log INFO "Summary report saved to: $output_file"
}

# Generate file list comparison (files that exist in one but not the other)
generate_file_list_comparison() {
    local path1="$1"
    local path2="$2"
    local output_file="$3"

    log INFO "Generating file list comparison..."

    local temp_list1=$(mktemp)
    local temp_list2=$(mktemp)
    local exclude_str=$(build_find_excludes)

    # Get relative file paths
    if [ -n "$exclude_str" ]; then
        (cd "$path1" && eval "find . -type f $exclude_str" | sort) > "$temp_list1"
        (cd "$path2" && eval "find . -type f $exclude_str" | sort) > "$temp_list2"
    else
        (cd "$path1" && find . -type f | sort) > "$temp_list1"
        (cd "$path2" && find . -type f | sort) > "$temp_list2"
    fi

    local name1=$(get_folder_name "$path1")
    local name2=$(get_folder_name "$path2")

    echo "relative_path,status,location" > "$output_file"

    # Find files only in path1
    comm -23 "$temp_list1" "$temp_list2" | while read -r file; do
        echo "\"$file\",ONLY_IN_SOURCE,$name1" >> "$output_file"
    done

    # Find files only in path2
    comm -13 "$temp_list1" "$temp_list2" | while read -r file; do
        echo "\"$file\",ONLY_IN_TARGET,$name2" >> "$output_file"
    done

    # Count common files
    local common_count=$(comm -12 "$temp_list1" "$temp_list2" | wc -l | tr -d ' ')
    local only_in_1=$(comm -23 "$temp_list1" "$temp_list2" | wc -l | tr -d ' ')
    local only_in_2=$(comm -13 "$temp_list1" "$temp_list2" | wc -l | tr -d ' ')

    log INFO "Common files: $common_count"
    log INFO "Only in $name1: $only_in_1"
    log INFO "Only in $name2: $only_in_2"

    rm -f "$temp_list1" "$temp_list2"

    log INFO "File list comparison saved to: $output_file"
}

# Generate deep scan report with all subfolders to specified depth
generate_deep_scan() {
    local path1="$1"
    local path2="$2"
    local depth="$3"
    local output_file="$4"

    log INFO "Generating deep scan report (depth: $depth)..."

    local name1=$(get_folder_name "$path1")
    local name2=$(get_folder_name "$path2")

    # Create temporary files for each path
    local temp_file1=$(mktemp)
    local temp_file2=$(mktemp)
    local exclude_str=$(build_find_excludes)

    # Get all directories up to specified depth with sizes and file counts
    log DEBUG "Deep scanning $path1..."
    echo "rel_path,size_bytes,size_gb,file_count" > "$temp_file1"
    find "$path1" -maxdepth "$depth" -type d 2>/dev/null | while read -r dir; do
        local rel_path="${dir#$path1}"
        rel_path="${rel_path#/}"
        [ -z "$rel_path" ] && rel_path="."

        # Get size in bytes
        local size_bytes=$(du -sk "$dir" 2>/dev/null | cut -f1)
        size_bytes=$((size_bytes * 1024))

        # Convert to GB
        local size_gb=$(awk -v b="$size_bytes" 'BEGIN {printf "%.3f", b/1073741824}')

        # Count files in this directory (non-recursive, excluding patterns)
        if [ -n "$exclude_str" ]; then
            local file_count=$(eval "find \"$dir\" -maxdepth 1 -type f $exclude_str 2>/dev/null" | wc -l | tr -d ' ')
        else
            local file_count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
        fi

        echo "\"$rel_path\",$size_bytes,$size_gb,$file_count" >> "$temp_file1"
    done

    log DEBUG "Deep scanning $path2..."
    echo "rel_path,size_bytes,size_gb,file_count" > "$temp_file2"
    find "$path2" -maxdepth "$depth" -type d 2>/dev/null | while read -r dir; do
        local rel_path="${dir#$path2}"
        rel_path="${rel_path#/}"
        [ -z "$rel_path" ] && rel_path="."

        local size_bytes=$(du -sk "$dir" 2>/dev/null | cut -f1)
        size_bytes=$((size_bytes * 1024))

        local size_gb=$(awk -v b="$size_bytes" 'BEGIN {printf "%.3f", b/1073741824}')

        # Count files in this directory (non-recursive, excluding patterns)
        if [ -n "$exclude_str" ]; then
            local file_count=$(eval "find \"$dir\" -maxdepth 1 -type f $exclude_str 2>/dev/null" | wc -l | tr -d ' ')
        else
            local file_count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
        fi

        echo "\"$rel_path\",$size_bytes,$size_gb,$file_count" >> "$temp_file2"
    done

    # Create combined output
    echo "relative_path,size_gb_${name1},files_${name1},size_gb_${name2},files_${name2},size_diff_gb,files_diff,status" > "$output_file"

    # Join the files
    join -t, -a1 -a2 -o '0,1.2,1.3,1.4,2.2,2.3,2.4' -e "0" \
        <(tail -n +2 "$temp_file1" | sort -t, -k1) \
        <(tail -n +2 "$temp_file2" | sort -t, -k1) \
        | while IFS=, read -r path size_bytes1 size_gb1 files1 size_bytes2 size_gb2 files2; do
            # Remove quotes from path
            path=$(echo "$path" | tr -d '"')

            # Handle missing values and ensure integers for file counts
            if [ "$size_bytes1" = "0" ] || [ -z "$size_bytes1" ]; then
                size_bytes1="0"
                size_gb1="0.000"
                files1="0"
            fi
            if [ "$size_bytes2" = "0" ] || [ -z "$size_bytes2" ]; then
                size_bytes2="0"
                size_gb2="0.000"
                files2="0"
            fi

            # Ensure file counts are integers (strip any decimals)
            files1=${files1%.*}
            files2=${files2%.*}

            # Default to 0 if empty
            : ${files1:=0}
            : ${files2:=0}

            # Calculate differences
            local size_diff_gb=$(awk -v s1="$size_gb1" -v s2="$size_gb2" 'BEGIN {printf "%.3f", s2 - s1}')
            local files_diff=$((files2 - files1))

            # Determine status
            local status
            if [ "$size_bytes1" = "0" ] && [ "$size_bytes2" = "0" ]; then
                status="BOTH_EMPTY"
            elif [ "$size_bytes1" = "0" ]; then
                status="ONLY_IN_${name2}"
            elif [ "$size_bytes2" = "0" ]; then
                status="ONLY_IN_${name1}"
            elif [ "$size_bytes1" = "$size_bytes2" ] && [ "$files1" = "$files2" ]; then
                status="IDENTICAL"
            else
                status="DIFFERENT"
            fi

            # Apply diff-only filter if requested
            if [ "$SHOW_DIFFERENCES_ONLY" = true ] && [ "$status" = "IDENTICAL" ]; then
                continue
            fi

            echo "\"$path\",$size_gb1,$files1,$size_gb2,$files2,$size_diff_gb,$files_diff,$status" >> "$output_file"
        done

    # Clean up
    rm -f "$temp_file1" "$temp_file2"

    log INFO "Deep scan report saved to: $output_file"
}

# Main function
main() {
    parse_args "$@"
    validate_inputs

    # Set up log file if not specified
    if [ -z "$LOG_FILE" ]; then
        LOG_FILE="${OUTPUT_DIR}/folder_compare_$(date +%Y%m%d_%H%M%S).log"
    fi

    # Create log file
    : > "$LOG_FILE"

    log INFO "========================================="
    log INFO "Folder Comparison Tool"
    log INFO "========================================="
    log INFO "Path 1: $PATH1"
    log INFO "Path 2: $PATH2"
    log INFO "Depth: $DEPTH"
    log INFO "File types: ${FILE_TYPES[*]:-none}"
    log INFO "Case insensitive: $CASE_INSENSITIVE"
    log INFO "Deep scan: $DEEP_SCAN"
    [ "$DEEP_SCAN" = true ] && log INFO "Deep scan depth: $DEEP_SCAN_DEPTH"
    log INFO "Always excluded: ${ALWAYS_EXCLUDE[*]}"
    [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ] && log INFO "User exclusions: ${EXCLUDE_PATTERNS[*]}"
    log INFO "Output directory: $OUTPUT_DIR"
    log INFO "Log file: $LOG_FILE"
    log INFO "========================================="

    # Generate output filenames
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local name1=$(get_folder_name "$PATH1")
    local name2=$(get_folder_name "$PATH2")
    local base_name="${OUTPUT_DIR}/compare_${name1}_vs_${name2}_${timestamp}"

    local summary_file="${base_name}_summary.csv"
    local size_file="${base_name}_sizes.csv"
    local filetype_file="${base_name}_filetypes.csv"
    local filelist_file="${base_name}_file_differences.csv"
    local deepscan_file="${base_name}_deep_scan.csv"

    # Generate comparisons
    generate_summary "$PATH1" "$PATH2" "$summary_file"
    generate_size_comparison "$PATH1" "$PATH2" "$size_file"

    if [ ${#FILE_TYPES[@]} -gt 0 ]; then
        generate_filetype_comparison "$PATH1" "$PATH2" "$filetype_file"
    fi

    generate_file_list_comparison "$PATH1" "$PATH2" "$filelist_file"

    # Generate deep scan if requested
    if [ "$DEEP_SCAN" = true ]; then
        generate_deep_scan "$PATH1" "$PATH2" "$DEEP_SCAN_DEPTH" "$deepscan_file"
    fi

    # Final summary
    log INFO "========================================="
    log INFO "Comparison complete!"
    log INFO "========================================="
    log INFO "Generated files:"
    log INFO "  - Summary: $summary_file"
    log INFO "  - Size comparison: $size_file"
    [ ${#FILE_TYPES[@]} -gt 0 ] && log INFO "  - File type comparison: $filetype_file"
    log INFO "  - File differences: $filelist_file"
    [ "$DEEP_SCAN" = true ] && log INFO "  - Deep scan: $deepscan_file"
    log INFO "  - Log file: $LOG_FILE"
    log INFO "========================================="

    # Open the summary file (macOS)
    if command -v open &> /dev/null; then
        log INFO "Opening summary file..."
        open "$summary_file"
    fi
}

# Run main function
main "$@"
