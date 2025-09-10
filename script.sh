#!/bin/bash

# Large Files and Directories Finder
# Finds directories and individual files over specified size threshold

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
SEARCH_PATH="${1:-.}"  # Default to current directory if no path provided
MIN_SIZE="${2:-1G}"    # Default to 1GB if no size provided
MAX_DEPTH="${3:-10}"   # Default max depth to avoid infinite recursion

# Function to display usage
show_usage() {
    echo "Usage: $0 [search_path] [min_size] [max_depth]"
    echo "  search_path: Directory to search (default: current directory)"
    echo "  min_size: Minimum size threshold (default: 1G)"
    echo "            Examples: 1G, 500M, 2048K, 1073741824 (bytes)"
    echo "  max_depth: Maximum directory depth to search (default: 10)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Search current dir for files/dirs > 1GB"
    echo "  $0 /home 500M 5      # Search /home for files/dirs > 500MB, max depth 5"
    echo "  $0 /var/log 100M     # Search /var/log for files/dirs > 100MB"
}

# Function to convert size to human readable format
human_readable() {
    local size=$1
    if (( size >= 1073741824 )); then
        printf "%.2fG" $(echo "scale=2; $size / 1073741824" | bc -l)
    elif (( size >= 1048576 )); then
        printf "%.2fM" $(echo "scale=2; $size / 1048576" | bc -l)
    elif (( size >= 1024 )); then
        printf "%.2fK" $(echo "scale=2; $size / 1024" | bc -l)
    else
        printf "%dB" $size
    fi
}

# Function to convert size specification to bytes
size_to_bytes() {
    local size_spec=$1
    local number=$(echo $size_spec | sed 's/[^0-9.]//g')
    local unit=$(echo $size_spec | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')
    
    case $unit in
        "G"|"GB") echo $(echo "$number * 1073741824" | bc -l | cut -d. -f1) ;;
        "M"|"MB") echo $(echo "$number * 1048576" | bc -l | cut -d. -f1) ;;
        "K"|"KB") echo $(echo "$number * 1024" | bc -l | cut -d. -f1) ;;
        "") echo $number ;;
        *) echo $number ;;
    esac
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Check if required tools are available
for tool in find du bc; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}Error: $tool is not installed${NC}"
        exit 1
    fi
done

# Validate search path
if [[ ! -d "$SEARCH_PATH" ]]; then
    echo -e "${RED}Error: Directory '$SEARCH_PATH' does not exist${NC}"
    exit 1
fi

# Convert size threshold to bytes for comparison
SIZE_BYTES=$(size_to_bytes $MIN_SIZE)

echo -e "${BLUE}=== Large Files and Directories Finder ===${NC}"
echo -e "${YELLOW}Search Path:${NC} $SEARCH_PATH"
echo -e "${YELLOW}Minimum Size:${NC} $MIN_SIZE (${SIZE_BYTES} bytes)"
echo -e "${YELLOW}Maximum Depth:${NC} $MAX_DEPTH"
echo ""

# Create temporary files for results
TEMP_FILES=$(mktemp)
TEMP_DIRS=$(mktemp)

# Clean up temp files on exit
trap "rm -f $TEMP_FILES $TEMP_DIRS" EXIT

echo -e "${GREEN}Scanning for large files...${NC}"

# Find large individual files
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE 2>/dev/null | while read -r file; do
    if [[ -r "$file" ]]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        if [[ -n "$size" && $size -gt $SIZE_BYTES ]]; then
            echo "$size|$file" >> $TEMP_FILES
        fi
    fi
done

echo -e "${GREEN}Scanning for large directories...${NC}"

# Find large directories
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type d 2>/dev/null | while read -r dir; do
    if [[ -r "$dir" ]]; then
        # Get directory size (including subdirectories)
        size=$(du -sb "$dir" 2>/dev/null | cut -f1)
        if [[ -n "$size" && $size -gt $SIZE_BYTES ]]; then
            echo "$size|$dir" >> $TEMP_DIRS
        fi
    fi
done

echo ""
echo -e "${BLUE}=== LARGE FILES (over $MIN_SIZE) ===${NC}"

if [[ -s $TEMP_FILES ]]; then
    # Sort files by size (largest first) and display
    sort -t'|' -k1 -nr $TEMP_FILES | while IFS='|' read -r size file; do
        readable_size=$(human_readable $size)
        echo -e "${RED}$readable_size${NC}\t$file"
    done
else
    echo -e "${YELLOW}No large files found${NC}"
fi

echo ""
echo -e "${BLUE}=== LARGE DIRECTORIES (over $MIN_SIZE) ===${NC}"

if [[ -s $TEMP_DIRS ]]; then
    # Sort directories by size (largest first) and display
    sort -t'|' -k1 -nr $TEMP_DIRS | while IFS='|' read -r size dir; do
        readable_size=$(human_readable $size)
        echo -e "${RED}$readable_size${NC}\t$dir"
    done
else
    echo -e "${YELLOW}No large directories found${NC}"
fi

echo ""
echo -e "${BLUE}=== SUMMARY ===${NC}"

# Count results
file_count=$(wc -l < $TEMP_FILES 2>/dev/null || echo 0)
dir_count=$(wc -l < $TEMP_DIRS 2>/dev/null || echo 0)

echo -e "${YELLOW}Large files found:${NC} $file_count"
echo -e "${YELLOW}Large directories found:${NC} $dir_count"

# Calculate total size
if [[ $file_count -gt 0 ]]; then
    total_file_size=$(awk -F'|' '{sum += $1} END {print sum}' $TEMP_FILES)
    echo -e "${YELLOW}Total size of large files:${NC} $(human_readable $total_file_size)"
fi

if [[ $dir_count -gt 0 ]]; then
    total_dir_size=$(awk -F'|' '{sum += $1} END {print sum}' $TEMP_DIRS)
    echo -e "${YELLOW}Total size of large directories:${NC} $(human_readable $total_dir_size)"
fi

echo ""
echo -e "${GREEN}Scan completed!${NC}"
