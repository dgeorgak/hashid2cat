#!/bin/bash

# Check if hashid is installed
if ! command -v hashid &> /dev/null; then
    read -p "hashid is not installed. Would you like to install it? (Y/N): " choice
    case "$choice" in
        y|Y)
	    sudo apt update && sudo apt install -y hashid
            ;;
        n|N)
	    echo "hashid not installed.  Please install manually and rerun hashid2cat."
	    exit 1
            ;;
        *)
            echo "Invalid response.  Exiting."
            exit 1
            ;;
    esac
fi

# Check if an input string is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_string>"
    echo "Example: hashid2cat.sh 202cb962ac59075b964b07152d234b70"
    exit 1
fi

# Input string
input_string="$1"

# Run hashid on the input string
output=$(hashid "$input_string")

# Check if the output is "unknown hash"
if echo "$output" | grep -q "Unknown hash"; then
    echo "unknown hash"
    exit 0
fi

# Extract probable hash types, remove "[+] ", and save to a file
file_name="${input_string:0:10}-hashtypes.txt"
echo "$output" | grep "\[+\] " | sed 's/^\[+\] //' > "$file_name"

# Display the extracted hash types
cat "$file_name"
