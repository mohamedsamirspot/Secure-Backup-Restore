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
        # $#: This variable holds the number of command-line arguments that were passed to the script.
        print_color "red" "You should enter 4 parameters: $0 <source_directory> <backup_directory> <encryption-key> <num_days>"
        # $0: This variable holds the name of the script itself (including its path, if it was invoked with a path)
        exit 1
        # The command exit 1 is used to terminate the script with a non-zero exit status, indicating that the script encountered an error or didn't execute successfully.
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
        # the -p option used with the mkdir command ensures that the parent directories of the specified directory are also created if they don't exist.
        if [ $? -ne 0 ]; then
            # if [ $? -ne 0 ]; then: After attempting to create the directory, this line checks the exit status of the mkdir command. The special variable $? contains the exit status of the last executed command.
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
        # -mindepth 1: This option ensures that the search starts from a depth of at least 1, meaning it excludes the source directory itself from the results.
        # -type d: This specifies that only directories should be considered in the search.
        # -print: This option prints the path of each directory that matches the conditions.
        # while read -r dir; do: This part of the command starts a loop that reads the paths of directories found by the find command. The -r option is used with read to ensure that backslashes are not treated as escape characters.
        # dir_name=$(basename "$dir"): This line extracts the base name of the directory path stored in the dir variable. The basename command removes the path and returns only the directory's name.
        dir_name=$(basename "$dir")
        tar -czf - -C "$source_directory" "$dir_name" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" > "$backup_directory/${dir_name}_${current_date}.tar.gz.enc"    # (-) after tar czf indicates that the output should be sent to the standard output (stdout) instead of creating an actual file. This is often used for piping data to another command.
        # c indicates that you're creating an archive. Yes, the -c option is mandatory when you want to create an archive using the tar command. The -c option indicates that you are creating an archive. It's an essential part of the command syntax for creating tar archives.
        # z indicates that you want to compress the archive using gzip.
        # f specifies the output file name.
        # tar czf: This is the command to create a compressed tar archive.
        # -C "$source_directory": This option tells tar to change to the source directory before archiving the contents of the directory. It helps maintain the relative directory structure within the archive.
        # "$dir_name": This specifies the directory that should be archived within the source directory.
        # For example, if your source directory is /path/to/source and you're archiving a subdirectory named subdir, without the -C option, the archive might have a path like /path/to/source/subdir. But with the -C option, the archive will only contain the contents of subdir without including the source part of the path.
        # y3ne rkz fy awl el command kda htla2ene b7dd el esm bs enma fy a5r el command ana b7dd el mkan bta3o w esmo a asln mn el awl
    done
    
    
    
    # Create a temporary directory to store the files
    temp_dir=$(mktemp -d)
    # Add files to the temporary directory
    find "$source_directory" -mindepth 1 -type f -mtime -$days -exec cp -t "$temp_dir" {} +
    # -mtime -$days: This option is used to select files based on their modification time. Specifically, it selects files that were modified within the last $days days. The - sign before $days indicates "less than," so you're selecting files that are older than $days days.
    # Encrypt and backup the files
    tar -czf - -C "$temp_dir" . | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" -out "$backup_directory/files_${current_date}.tar.gz.enc"
    # Clean up temporary files and directory
    rm -rf "$temp_dir"
    print_color "green" "Backup completed."
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