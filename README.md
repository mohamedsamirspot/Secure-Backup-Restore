# Secure-Backup-Restore
![images](https://github.com/mohamedsamirspot/Secure-Backup-Restore/assets/71722372/07d3e5c5-848a-492b-abdf-d4b077d27001) ![rsz_data-backup-strategy-e1630681061437](https://github.com/mohamedsamirspot/Secure-Backup-Restore/assets/71722372/78374f68-ea8c-4015-b184-a37134bc9e45)



2 bash scripts that perform secure encrypted backup and restore functionality. You should be able to maneuver through the Linux configuration files and be able to schedule running the backup script on predefined times. Finally, you will need to copy the backup to a remote server.


first create the syemmtric encryption key

    openssl rand -base64 32 > encryption.key

to use the backup script
    
     ./backup.sh <source_directory> <backup_directory> <encryption-key> <num_days>

to decrypt 

    openssl enc -d -aes-256-cbc -pbkdf2 -in encrypted-archive.tar.gz.enc -out decrypted-archive.tar.gz -pass file:encryption.key-path(full-path not relative path)
When specifying the path to the key file in the openssl command either in enc or dec, you need to provide the full absolute path to the key file. Relative paths like ../encryption.key might not work as expected because the working directory might not be what you expect when running the command.
like this:
    
    openssl enc -d -aes-256-cbc -pbkdf2 -in files_2023_08_23_23_16_53.tar.gz.enc -out decrypted-archive.tar.gz -pass file:/home/spot/Downloads/Secure-Backup-Restore/encryption.key


to use the restore script

    ./restore.sh <backup_directory> <restore_directory> <decryption-key>
