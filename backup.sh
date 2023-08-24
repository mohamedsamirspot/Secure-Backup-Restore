#!/bin/bash

# Source the library script
. backup_restore_lib.sh

# Call the validate_backup_params function
validate_backup_params "$@"

# Call the backup function
backup "$1" "$2" "$3" "$4"