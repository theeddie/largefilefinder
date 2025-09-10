#!/bin/bash

# Fast Large Files and Directories Finder
# Optimized version for speed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
SEARCH_PATH="${1:-.}"
MIN_SIZE="${2:-1G}"
MAX_DEPTH="${3:-5}"  # Reduced default depth for speed

# Function to display usage
show_usage() {
    echo "Usage: $0 [search_path] [min_size] [max_depth]"
    echo "  search_path: Directory to search (default: current directory)"
    echo "  min_size: Minimum size threshold (default: 1G)"
    echo "  max_depth: Maximum directory depth (default: 5 for speed)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Fast search current dir > 1GB"
    echo "  $0 /home 500M 3      # Search /home > 500MB, depth 3"
    echo "  $0 /var 100M 2       # Quick search /var > 100MB, depth 2"
}

# Function to convert size to human readable
human_readable() {
    local size=$1
    if (( size >= 1073741824 )); then
        printf "%.1fG" $(awk "BEGIN {printf \"%.1f\", $size/1073741824}")
    elif (( size >= 1048576 )); then
        printf "%.1fM" $(awk "BEGIN {printf \"%.1f\", $size/1048576}")
    elif (( size >= 1024 )); then
        printf "%.1fK" $(awk "BEGIN {printf \"%.1f\", $size/1024}")
    else
        printf "%dB" $size
    fi
}

# Check if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Validate path
if [[ ! -d "$SEARCH_PATH" ]]; then
    echo -e "${RED}Error: Directory '$SEARCH_PATH' does not exist${NC}"
    exit 1
fi

echo -e "${BLUE}=== Fast Large Files Finder ===${NC}"
echo -e "${YELLOW}Path:${NC} $SEARCH_PATH | ${YELLOW}Size:${NC} $MIN_SIZE | ${YELLOW}Depth:${NC} $MAX_DEPTH"
echo ""

echo -e "${GREEN}Finding large files (>$MIN_SIZE)...${NC}"

# Fast file search - single find command, sorted immediately
echo -e "${BLUE}=== LARGE FILES ===${NC}"
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE -exec ls -lh {} + 2>/dev/null | \
    sort -k5 -hr | \
    head -20 | \
    awk '{printf "\033[0;31m%s\033[0m\t%s/%s\n", $5, $(NF-2), $NF}' 2>/dev/null || \
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE -ls 2>/dev/null | \
    sort -k7 -nr | \
    head -20 | \
    awk '{size=$7; if(size>=1073741824) sz=sprintf("%.1fG",size/1073741824); else if(size>=1048576) sz=sprintf("%.1fM",size/1048576); else if(size>=1024) sz=sprintf("%.1fK",size/1024); else sz=size"B"; printf "\033[0;31m%s\033[0m\t%s\n", sz, $11}'

echo ""
echo -e "${GREEN}Finding large directories (top-level only for speed)...${NC}"

# Fast directory search - limited depth for speed
echo -e "${BLUE}=== LARGE DIRECTORIES ===${NC}"
if command -v du >/dev/null 2>&1; then
    # Use du with limited depth for speed
    du -h --max-depth=$MAX_DEPTH "$SEARCH_PATH" 2>/dev/null | \
        awk -v min="$MIN_SIZE" '
        BEGIN {
            if(min ~ /G$/) minbytes = substr(min,1,length(min)-1) * 1024 * 1024 * 1024
            else if(min ~ /M$/) minbytes = substr(min,1,length(min)-1) * 1024 * 1024  
            else if(min ~ /K$/) minbytes = substr(min,1,length(min)-1) * 1024
            else minbytes = min
        }
        {
            size = $1
            bytes = 0
            if(size ~ /G$/) bytes = substr(size,1,length(size)-1) * 1024 * 1024 * 1024
            else if(size ~ /M$/) bytes = substr(size,1,length(size)-1) * 1024 * 1024
            else if(size ~ /K$/) bytes = substr(size,1,length(size)-1) * 1024
            else bytes = size
            
            if(bytes >= minbytes) {
                printf "\033[0;31m%s\033[0m\t%s\n", $1, $2
            }
        }' | \
        sort -k1 -hr | \
        head -15
else
    echo -e "${YELLOW}du command not available, skipping directory sizes${NC}"
fi

echo ""
echo -e "${GREEN}Quick summary:${NC}"

# Quick counts
file_count=$(find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE 2>/dev/null | wc -l)
echo -e "${YELLOW}Large files found:${NC} $file_count (showing top 20)"

if command -v du >/dev/null 2>&1; then
    dir_count=$(du -h --max-depth=$MAX_DEPTH "$SEARCH_PATH" 2>/dev/null | awk -v min="$MIN_SIZE" 'BEGIN{if(min~/G$/)mb=substr(min,1,length(min)-1)*1024;else if(min~/M$/)mb=substr(min,1,length(min)-1);else mb=1024} {if($1~/G$/)sz=substr($1,1,length($1)-1)*1024;else if($1~/M$/)sz=substr($1,1,length($1)-1);else sz=0; if(sz>=mb)c++} END{print c+0}')
    echo -e "${YELLOW}Large directories found:${NC} $dir_count (showing top 15)"
fi

echo ""
echo -e "${BLUE}Tips for faster searches:${NC}"
echo -e "• Use smaller max depth (2-3) for very fast results"
echo -e "• Increase depth slowly if you need deeper search"
echo -e "• For complete scan, use: find /path -size +1G -ls"

echo -e "${GREEN}Done!${NC}"#!/bin/bash

# Fast Large Files and Directories Finder
# Optimized version for speed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
SEARCH_PATH="${1:-.}"
MIN_SIZE="${2:-1G}"
MAX_DEPTH="${3:-5}"  # Reduced default depth for speed

# Function to display usage
show_usage() {
    echo "Usage: $0 [search_path] [min_size] [max_depth]"
    echo "  search_path: Directory to search (default: current directory)"
    echo "  min_size: Minimum size threshold (default: 1G)"
    echo "  max_depth: Maximum directory depth (default: 5 for speed)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Fast search current dir > 1GB"
    echo "  $0 /home 500M 3      # Search /home > 500MB, depth 3"
    echo "  $0 /var 100M 2       # Quick search /var > 100MB, depth 2"
}

# Function to convert size to human readable
human_readable() {
    local size=$1
    if (( size >= 1073741824 )); then
        printf "%.1fG" $(awk "BEGIN {printf \"%.1f\", $size/1073741824}")
    elif (( size >= 1048576 )); then
        printf "%.1fM" $(awk "BEGIN {printf \"%.1f\", $size/1048576}")
    elif (( size >= 1024 )); then
        printf "%.1fK" $(awk "BEGIN {printf \"%.1f\", $size/1024}")
    else
        printf "%dB" $size
    fi
}

# Check if help requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Validate path
if [[ ! -d "$SEARCH_PATH" ]]; then
    echo -e "${RED}Error: Directory '$SEARCH_PATH' does not exist${NC}"
    exit 1
fi

echo -e "${BLUE}=== Fast Large Files Finder ===${NC}"
echo -e "${YELLOW}Path:${NC} $SEARCH_PATH | ${YELLOW}Size:${NC} $MIN_SIZE | ${YELLOW}Depth:${NC} $MAX_DEPTH"
echo ""

echo -e "${GREEN}Finding large files (>$MIN_SIZE)...${NC}"

# Fast file search - single find command, sorted immediately
echo -e "${BLUE}=== LARGE FILES ===${NC}"
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE -exec ls -lh {} + 2>/dev/null | \
    sort -k5 -hr | \
    head -20 | \
    awk '{printf "\033[0;31m%s\033[0m\t%s/%s\n", $5, $(NF-2), $NF}' 2>/dev/null || \
find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE -ls 2>/dev/null | \
    sort -k7 -nr | \
    head -20 | \
    awk '{size=$7; if(size>=1073741824) sz=sprintf("%.1fG",size/1073741824); else if(size>=1048576) sz=sprintf("%.1fM",size/1048576); else if(size>=1024) sz=sprintf("%.1fK",size/1024); else sz=size"B"; printf "\033[0;31m%s\033[0m\t%s\n", sz, $11}'

echo ""
echo -e "${GREEN}Finding large directories (top-level only for speed)...${NC}"

# Fast directory search - limited depth for speed
echo -e "${BLUE}=== LARGE DIRECTORIES ===${NC}"
if command -v du >/dev/null 2>&1; then
    # Use du with limited depth for speed
    du -h --max-depth=$MAX_DEPTH "$SEARCH_PATH" 2>/dev/null | \
        awk -v min="$MIN_SIZE" '
        BEGIN {
            if(min ~ /G$/) minbytes = substr(min,1,length(min)-1) * 1024 * 1024 * 1024
            else if(min ~ /M$/) minbytes = substr(min,1,length(min)-1) * 1024 * 1024  
            else if(min ~ /K$/) minbytes = substr(min,1,length(min)-1) * 1024
            else minbytes = min
        }
        {
            size = $1
            bytes = 0
            if(size ~ /G$/) bytes = substr(size,1,length(size)-1) * 1024 * 1024 * 1024
            else if(size ~ /M$/) bytes = substr(size,1,length(size)-1) * 1024 * 1024
            else if(size ~ /K$/) bytes = substr(size,1,length(size)-1) * 1024
            else bytes = size
            
            if(bytes >= minbytes) {
                printf "\033[0;31m%s\033[0m\t%s\n", $1, $2
            }
        }' | \
        sort -k1 -hr | \
        head -15
else
    echo -e "${YELLOW}du command not available, skipping directory sizes${NC}"
fi

echo ""
echo -e "${GREEN}Quick summary:${NC}"

# Quick counts
file_count=$(find "$SEARCH_PATH" -maxdepth $MAX_DEPTH -type f -size +$MIN_SIZE 2>/dev/null | wc -l)
echo -e "${YELLOW}Large files found:${NC} $file_count (showing top 20)"

if command -v du >/dev/null 2>&1; then
    dir_count=$(du -h --max-depth=$MAX_DEPTH "$SEARCH_PATH" 2>/dev/null | awk -v min="$MIN_SIZE" 'BEGIN{if(min~/G$/)mb=substr(min,1,length(min)-1)*1024;else if(min~/M$/)mb=substr(min,1,length(min)-1);else mb=1024} {if($1~/G$/)sz=substr($1,1,length($1)-1)*1024;else if($1~/M$/)sz=substr($1,1,length($1)-1);else sz=0; if(sz>=mb)c++} END{print c+0}')
    echo -e "${YELLOW}Large directories found:${NC} $dir_count (showing top 15)"
fi

echo ""
echo -e "${BLUE}Tips for faster searches:${NC}"
echo -e "• Use smaller max depth (2-3) for very fast results"
echo -e "• Increase depth slowly if you need deeper search"
echo -e "• For complete scan, use: find /path -size +1G -ls"

echo -e "${GREEN}Done!${NC}"
