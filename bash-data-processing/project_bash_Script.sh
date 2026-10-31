#!/bin/bash

set -euo pipefail

# ==========================================
# Bash Data Processing Toolkit
# ==========================================

DataDir="data"
OutputDir="output"
LogDir="log"
Logfile="$LogDir/project.log"

log_message() {
    local level="$1"
    local message="$2"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $level: $message" | tee -a "$Logfile"
}

# ------------------------------------------
# Initialize Directories
# ------------------------------------------
InitDir() {
    if mkdir -p "$DataDir" "$OutputDir" "$LogDir" &&
       touch "$Logfile"; then
        log_message "SUCCESS" "Directories initialized successfully"
    else
        echo "ERROR: Failed to initialize directories" >&2
        return 1
    fi
}

# ------------------------------------------
# Check If Command Exists
# ------------------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------
# Check Project Dependencies
# ------------------------------------------
check_dependencies() {
    local commands=("awk" "sort" "uniq" "wc" "cut" "grep" "cat")
    local miss=0
    local commandname

    for commandname in "${commands[@]}"; do
        if command_exists "$commandname"; then
            log_message "SUCCESS" "Command found: $commandname"
        else
            log_message "ERROR" "Command not found: $commandname"
            miss=1
        fi
    done

    if [[ "$miss" -eq 0 ]]; then
        log_message "SUCCESS" "All dependencies are available"
    else
        return 1
    fi
}

# ------------------------------------------
# Count Lines
# ------------------------------------------
countLines() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi

    local count
    count=$(wc -l < "$file")

    log_message "INFO" "File: $file"
    log_message "SUCCESS" "Number of lines: $count"
}

# ------------------------------------------
# Extract Columns From CSV
# ------------------------------------------
extract_columns() {
    local file="$1"
    local column="$2"
    local output="$OutputDir/extracted_columns.txt"

    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi

    if cut -d ',' -f "$column" "$file" > "$output"; then
        log_message "SUCCESS" "Extracted columns saved to $output"
    else
        log_message "ERROR" "Extraction failed"
        return 1
    fi
}

# ------------------------------------------
# Filter Lines By Keyword
# ------------------------------------------
filter_data() {
    local file="$1"
    local keyword="$2"
    local output_file="$OutputDir/filtered_data.txt"
    local status

    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi

    if grep -iF -- "$keyword" "$file" > "$output_file"; then
        log_message "SUCCESS" "Filtered data saved to $output_file"
    else
        status=$?

        if [[ "$status" -eq 1 ]]; then
            log_message "WARNING" "No matching lines found"
            : > "$output_file"
        else
            log_message "ERROR" "Filtering failed"
            return "$status"
        fi
    fi
}

# ------------------------------------------
# Calculate Basic Statistics
# ------------------------------------------
calculate_stats() {
    local file="$1"
    local output_file="$OutputDir/statistics.txt"

    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi

    local line_count
    line_count=$(wc -l < "$file")

    log_message "INFO" "Calculating statistics for $file"
    log_message "SUCCESS" "Line count: $line_count"

    if awk '
        NF {
            if ($1 !~ /^-?[0-9]+([.][0-9]+)?$/) {
                next
            }

            sum += $1
            count++

            if (count == 1 || $1 < min) min = $1
            if (count == 1 || $1 > max) max = $1
        }

        END {
            if (count == 0) {
                print "No numeric data found"
            } else {
                printf "Sum: %g\nAverage: %.2f\nMin: %g\nMax: %g\n",
                       sum, sum / count, min, max
            }
        }
    ' "$file" > "$output_file"; then
        log_message "SUCCESS" "Statistics saved to $output_file"
        cat "$output_file"
    else
        log_message "ERROR" "Failed to calculate statistics"
        return 1
    fi
}

# ------------------------------------------
# Merge Two Files
# ------------------------------------------
merge_files() {
    local file1="$1"
    local file2="$2"
    local output_file="$OutputDir/merged_data.txt"

    if [[ ! -f "$file1" || ! -f "$file2" ]]; then
        log_message "ERROR" "One or both input files do not exist"
        return 1
    fi

    if cat "$file1" "$file2" > "$output_file"; then
        log_message "SUCCESS" "Files merged into $output_file"
    else
        log_message "ERROR" "Failed to merge files"
        return 1
    fi
}

# ------------------------------------------
# Remove Duplicate Lines
# ------------------------------------------
deduplicate() {
    local file="$1"
    local output_file="$OutputDir/deduplicated_data.txt"

    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi

    if awk '!seen[$0]++' "$file" > "$output_file"; then
        log_message "SUCCESS" "Duplicates removed; saved to $output_file"
    else
        log_message "ERROR" "Failed to remove duplicates"
        return 1
    fi
}

# ------------------------------------------
# Main Menu
# ------------------------------------------
show_menu() {
    echo
    echo "=========================================="
    echo "       Bash Data Processing Toolkit"
    echo "=========================================="
    echo "1. Count lines in a file"
    echo "2. Extract columns from CSV"
    echo "3. Filter data by keyword"
    echo "4. Calculate statistics for numbers"
    echo "5. Merge two files"
    echo "6. Remove duplicate lines"
    echo "7. Check dependencies"
    echo "8. Initialize directories"
    echo "9. Exit"
    echo "=========================================="
}

# ------------------------------------------
# Main Program
# ------------------------------------------
main() {
    InitDir
    log_message "INFO" "Script started"

    while true; do
        show_menu

        read -r -p "Choose an option (1-9): " choice

        case "$choice" in
            1)
                read -r -p "Enter file path [data/data.txt]: " file
                file="${file:-data/data.txt}"

                countLines "$file" || true
                ;;

            2)
                read -r -p "Enter CSV file path [data/data.csv]: " file
                file="${file:-data/data.csv}"

                read -r -p "Enter column numbers, e.g. 2 or 2,4: " columns

                extract_columns "$file" "$columns" || true
                ;;

            3)
                read -r -p "Enter file path [data/data.txt]: " file
                file="${file:-data/data.txt}"

                read -r -p "Enter keyword: " keyword

                filter_data "$file" "$keyword" || true
                ;;

            4)
                read -r -p "Enter numbers file [data/numbers.txt]: " file
                file="${file:-data/numbers.txt}"

                calculate_stats "$file" || true
                ;;

            5)
                read -r -p "Enter first file [data/data.txt]: " file1
                file1="${file1:-data/data.txt}"

                read -r -p "Enter second file [data/sample.txt]: " file2
                file2="${file2:-data/sample.txt}"

                merge_files "$file1" "$file2" || true
                ;;

            6)
                read -r -p "Enter file path [data/sample.txt]: " file
                file="${file:-data/sample.txt}"

                deduplicate "$file" || true
                ;;

            7)
                check_dependencies || true
                ;;

            8)
                InitDir || true
                ;;

            9)
                log_message "INFO" "Script stopped by user"
                echo "Goodbye!"
                break
                ;;

            *)
                log_message "WARNING" "Invalid menu choice: $choice"
                echo "Please enter a number from 1 to 9."
                ;;
        esac
    done
}

main "$@"