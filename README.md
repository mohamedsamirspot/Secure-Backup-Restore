# Secure-Backup-Restore
![images](https://github.com/mohamedsamirspot/Secure-Backup-Restore/assets/71722372/07d3e5c5-848a-492b-abdf-d4b077d27001) ![rsz_data-backup-strategy-e1630681061437](https://github.com/mohamedsamirspot/Secure-Backup-Restore/assets/71722372/78374f68-ea8c-4015-b184-a37134bc9e45)



Bash scripts that perform secure encrypted backup and restore functionality, copying the backup to a remote server, and also scheduling running the backup script on predefined times using the crond utility.


## First create your syemmtric encryption and decryption key

    openssl rand -base64 32 > encryption.key

to try decrypting any file manually

    openssl enc -d -aes-256-cbc -pbkdf2 -in encrypted-archive.tar.gz.enc -out decrypted-archive.tar.gz -pass file:encryption.key-path(full-path not relative path)
When specifying the path to the key file in the openssl command either in enc or dec, you need to provide the full absolute path to the key file. Relative paths like ../encryption.key might not work as expected because the working directory might not be what you expect when running the command.
like this:

    openssl enc -d -aes-256-cbc -pbkdf2 -in files_2023_08_23_23_16_53.tar.gz.enc -out decrypted-archive.tar.gz -pass file:/home/spot/Downloads/Secure-Backup-Restore/encryption.key

## How to use the backup script
    
     ./backup.sh <source_directory> <backup_directory> <encryption-key> <num_days>
## How to use the restore script

    ./restore.sh <backup_directory> <restore_directory> <decryption-key>

## Schedule the run of the backup script
- To schedule this backup script using crond to run everyday at 2 am

        crontab -e
        0 2 * * * /path/to/backup_script.sh /path/to/source_directory /path/to/backup_destination "encryption_key-full-path" <num_days>
Here's what each field means:
0: Minute (0-59)
2: Hour (0-23)
*: Every day of the month
*: Every month
*: Every day of the week (0=Sunday, 1=Monday, ... 6=Saturday)
- Save and Exit:
- To Verify: This will display the list of scheduled cron jobs for your user.
    
        crontab -l

