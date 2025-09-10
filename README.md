1. Flexible Usage:

./script.sh - Search current directory for files/dirs > 1GB
./script.sh /home 500M 5 - Search /home for items > 500MB, max depth 5
./script.sh /var/log 100M - Search /var/log for items > 100MB

2. Size Format Support:

Supports various size formats: 1G, 500M, 2048K, or raw bytes
Automatically converts to human-readable format in output

3. Safety Features:

Maximum depth limit to prevent infinite recursion
Error handling for permission issues
Validates input parameters
Color-coded output for easy reading

4. Comprehensive Output:

Lists large files and directories separately
Sorts results by size (largest first)
Provides summary with counts and total sizes
Human-readable size formatting

To use the script:

Save it to a file (e.g., find_large.sh)
Make it executable: chmod +x find_large.sh
Run it: ./find_large.sh [path] [size] [depth]

# Ultra-fast (depth 2, current directory)
./find_large.sh . 1G 2

# Fast (depth 3, specific path)  
./find_large.sh /home 500M 3

# Balanced (default depth 5)
./find_large.sh /var 100M

# If you need complete results, use native find:
find /path -size +1G -ls | head -50
