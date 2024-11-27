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

input_string="$1"

# Run hashid on the input string
output=$(hashid "$input_string")

# Check if the hash type is not recognised
if echo "$output" | grep -q "Unknown hash"; then
    echo "unknown hash"
    exit 0
fi

# Extract hash types in a file and as an output message
file_name="${input_string:0:10}-hashtypes.txt"
echo "$output" | grep "\[+\] " | sed 's/^\[+\] //' > "$file_name"
# cat "$file_name"

# Parse hashcat manual for "Hash types"
hashcat_manual=$(man hashcat | sed -n '/^ *Hash types/,/^$/p')

# Match hash types in the hashcat manual
matches_found=0
hashcat_numbers_file="${input_string:0:10}-hashcat.txt"

while read -r hash_type; do
    match=$(echo "$hashcat_manual" | grep -i " = $hash_type" | awk -F ' ' '{print $1}')
    if [[ -n "$match" ]]; then
        echo "$match" >> "$hashcat_numbers_file"
        matches_found=1
    fi
done < "$file_name"

if [[ $matches_found -eq 0 ]]; then
    echo "No matches found in hashcat for the hash types requested"
    exit 1
fi

# TODO: switch to providing wordlist as script input with "-w"
wordlist="/usr/share/wordlists/rockyou.txt"

if [[ ! -f "$wordlist" ]]; then
    echo "Error: Wordlist $wordlist not found. Please ensure rockyou.txt is installed and available."
    exit 1
fi

modes=($(cat "$hashcat_numbers_file"))
i=0
if [ ${#modes[@]} -gt 0 ]; then
    # Run hashcat looping through detected hash types
    while [ $i -lt ${#modes[@]} ]; do
        mode=${modes[$i]}
        echo "Running hashcat with mode $mode"
        hashcat_output=$(hashcat -m "$mode" -a 0 "$input_string" "$wordlist" 2>&1)
        if echo "$hashcat_output" | grep -q "Recovered........: 1/1 (100.00%)" || echo "$hashcat_output" | grep -q "INFO: All hashes found as potfile and/or empty entries!"; then
            echo "Hash successfully cracked with mode $mode:"
        potfile_output=$(hashcat -m "$mode" -a 0 "$input_string" "$wordlist" --show 2>&1)
            rm "$hashcat_numbers_file"
            echo "$potfile_output"
            exit 0
        elif echo "$hashcat_output" | grep -q "Stopped:"; then
            echo "No results with mode $mode.  Proceeding to next mode."
            echo " "
        fi
        ((i++))
    done
else
    echo "No modes found"
    exit 0
fi    

echo "Hash not cracked with any of the detected modes."
exit 0
