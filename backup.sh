#!/bin/bash

. colors_function.sh

# Check for correct number of arguments
if [ "$#" -ne 4 ]; then
# $#: This variable holds the number of command-line arguments that were passed to the script. 
    print_color "red" "You should have 4 inputs: $0 <source_directory> <backup_directory> <num_days>"
    # $0: This variable holds the name of the script itself (including its path, if it was invoked with a path)
    exit 1
    # The command exit 1 is used to terminate the script with a non-zero exit status, indicating that the script encountered an error or didn't execute successfully.
fi

source_directory="$1"
backup_destination="$2"
encryption_key="$3"
days="$4"

# Create a variable to store the full date with underscores
current_date=$(date +"%Y_%m_%d_%H_%M_%S")

# Create backup directory if it doesn't exist
if [ ! -d "$backup_destination" ]; then
    mkdir -p "$backup_destination"
    # the -p option used with the mkdir command ensures that the parent directories of the specified directory are also created if they don't exist.
fi

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
    tar -czf - -C "$source_directory" "$dir_name" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" > "$backup_directory/${dir_name}.tar.gz.enc"    # (-) after tar czf indicates that the output should be sent to the standard output (stdout) instead of creating an actual file. This is often used for piping data to another command.
    # c indicates that you're creating an archive. Yes, the -c option is mandatory when you want to create an archive using the tar command. The -c option indicates that you are creating an archive. It's an essential part of the command syntax for creating tar archives.
    # z indicates that you want to compress the archive using gzip.
    # f specifies the output file name.
    # tar czf: This is the command to create a compressed tar archive.
    # -C "$source_directory": This option tells tar to change to the source directory before archiving the contents of the directory. It helps maintain the relative directory structure within the archive.
    # "$dir_name": This specifies the directory that should be archived within the source directory.
    # For example, if your source directory is /path/to/source and you're archiving a subdirectory named subdir, without the -C option, the archive might have a path like /path/to/source/subdir. But with the -C option, the archive will only contain the contents of subdir without including the source part of the path.
    # y3ne rkz fy awl el command kda htla2ene b7dd el esm bs enma fy a5r el command ana b7dd el mkan bta3o w esmo a asln mn el awl
done


# Backup changed files
find "$source_directory" -mindepth 1 -type f -mtime -$days -print | while read -r file; do
# -mtime -$days: This option is used to select files based on their modification time. Specifically, it selects files that were modified within the last $days days. The - sign before $days indicates "less than," so you're selecting files that are older than $days days.
    file_name=$(basename "$file")
tar -czf - -C "$source_directory" "$file_name" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:"$encryption_key" > "$backup_directory/${file_name}.tar.gz.enc"
done
print_color "green" "Backup completed."