#!/bin/bash

# Source the library script
. backup_restore_lib.sh

# Call the validate_restore_params function
validate_restore_params "$@"

# Call the restore function
restore "$@"