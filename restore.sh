#!/bin/bash

. backup_restore_lib.sh

# Check for correct number of arguments
if [ "$#" -ne 3 ]; then
    print_color "red" "You should enter 3 parameters: $0 <backup_directory> <restore_directory> <decryption-key>"
    exit 1
fi

backup_directory="$1"
restore_directory="$2"
decryption_key="$3"

# Check if the backup_directory is a directory
if [ ! -d "$backup_directory" ]; then
    print_color "red" "The backup directory '$backup_directory' does not exist or is not a directory."
    exit 1
fi

# Check if the restore_directory exists or create it
if [ ! -d "$restore_directory" ]; then
    mkdir -p "$restore_directory"
    if [ $? -ne 0 ]; then
        print_color "red" "Failed to create restore destination directory '$restore_directory'."
        exit 1
    fi
fi

# Check if the decryption_key file exists and is a file
if [ ! -f "$decryption_key" ]; then
    print_color "red" "The decryption key file '$decryption_key' does not exist or is not a file."
    exit 1
fi

# Loop over encrypted backup files and restore
for encrypted_file in "$backup_directory"/*enc; do
    if [ -f "$encrypted_file" ]; then
        decrypted_file="${encrypted_file%.enc}"
        openssl enc -d -aes-256-cbc -pbkdf2 -salt -pass file:"$decryption_key" -in "$encrypted_file" -out "$decrypted_file"
        
        if [[ $? -eq 0 ]]; then
            # Extract the decrypted tar.gz file
            tar -xzf "$decrypted_file" -C "$restore_directory"
            rm "$decrypted_file" # Clean up decrypted file
            print_color "blue" "Restored '$encrypted_file' to '$restore_directory'"
        else
            print_color "red" "Failed to decrypt '$encrypted_file'"
        fi
    fi
done

print_color "green" "Restore completed."
