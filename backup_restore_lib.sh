#!/bin/bash

function print_color(){
    #######################################
    # Print a message in a given color.
    # Arguments:
    #   Color. eg: green, red
    #######################################
    NC='\033[0m' # No Color
    case $1 in
        "red") COLOR='\033[0;31m' ;;
        "green") COLOR='\033[0;32m' ;;
        "blue") COLOR='\033[0;34m' ;;
        "*") COLOR='\033[0m' ;;
    esac
    
    echo -e "${COLOR} $2 ${NC}"
}

# Function to validate backup parameters
validate_backup_params() {
    # Check for correct number of arguments
    if [ "$#" -ne 4 ]; then
        print_color "red" "You should enter 4 parameters: $0 <source_directory> <backup_directory> <encryption-key> <num_days>"
        exit 1
    fi
    
    source_directory="$1"
    backup_destination="$2"
    encryption_key="$3"
    days="$4"
    
    # Check if the source_directory is a directory
    if [ ! -d "$source_directory" ]; then
        print_color "red" "The source directory '$source_directory' does not exist or is not a directory."
        exit 1
    fi
    
    # Check if the backup_destination is a directory or create it
    if [ ! -d "$backup_destination" ]; then
        mkdir -p "$backup_destination"
        if [ $? -ne 0 ]; then
            print_color "red" "Failed to create backup destination directory '$backup_destination'."
            exit 1
        fi
    fi
    
    # Check if the encryption_key file exists and is a file
    if [ ! -f "$encryption_key" ]; then
        print_color "red" "The encryption key file '$encryption_key' does not exist or is not a file."
        exit 1
    fi
    
    # Check if days is a valid number
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
        print_color "red" "The number of days '$days' is not a valid positive integer."
        exit 1
    fi
    
}

# Function to perform backup
backup() {
    source_directory="$1"
    backup_destination="$2"
    encryption_key="$3"
    days="$4"
    # Create a variable to store the full date with underscores
    current_date=$(date +"%Y_%m_%d_%H_%M_%S")
    
    # Create a directory with the formatted date
    backup_directory="$backup_destination/$current_date"
    mkdir -p "$backup_directory"
    
    # Backup all directories
    find "$source_directory" -mindepth 1 -type d -print | while read -r dir; do
        dir_name=$(basename "$dir")
        tar -czf - -C "$source_directory" "$dir_name" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" > "$backup_directory/${dir_name}_${current_date}.tar.gz.enc"    # (-) after tar czf indicates that the output should be sent to the standard output (stdout) instead of creating an actual file. This is often used for piping data to another command.
    done
    

    # Backup all files
    # Create a temporary directory to store the files
    temp_dir=$(mktemp -d)
    # Add files to the temporary directory
    find "$source_directory" -mindepth 1 -type f -mtime -$days -exec cp -t "$temp_dir" {} +
    # Encrypt and backup the files
    tar -czf - -C "$temp_dir" . | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" -out "$backup_directory/files_${current_date}.tar.gz.enc"
    # Clean up temporary files and directory
    rm -rf "$temp_dir"
    print_color "green" "Backup completed."
    # scp -r "$backup_directory" spot@34.66.40.221:~  
    # print_color "green" "Connection to remote server completed."
}

# Function to validate restore parameters
validate_restore_params() {
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
    
}

# Function to perform restore
restore() {
    backup_directory="$1"
    restore_directory="$2"
    decryption_key="$3"
    
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
}