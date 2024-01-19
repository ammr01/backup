# Backup Script

## Overview

This Bash script is designed for creating and managing backups of specified directories and files. It generates compressed tar archives, utilizing the pigz compression tool for improved performance. The backup files are organized in a directory structure based on the source directories, and older backups are automatically pruned.

## Usage

To run the script, use the following command:

```bash
./backup.sh <directories/files to backup (use absolute path, and separate by space)> -d <backup destination directory>
```
### Options

- `<directories/files>`: Specify the directories or files to be backed up using their absolute paths, separated by space.
- `-d` or `--destination`: Specify the backup destination directory.
- `--tar_arguments`: Specify additional arguments to be passed to the `tar` command during backup.
- `-n` or `--compare_names`: compare file names instead of tar files content in the destination directory, use this option only if you use the script as a cron job to save some resources.
- `-e` 

### Example

```bash
./backup.sh /path/to/directory1 /path/to/file.txt -d /path/to/backup/directory --tar_arguments="--exclude=*.log --exclude /home/user/koko.dd"
```
is same as 
```bash
./backup.sh /path/to/directory1 /path/to/file.txt -d /path/to/backup/directory -e *.log -e /home/user/koko.dd
```



## Features

- **Automatic Directory Creation**: The script checks if the specified backup destination directory exists and creates it if not.

- **Backup File Naming**: Each backup file is named based on the directories being backed up and the timestamp of the backup.

- **Backup Archive Compression**: The script uses pigz as a compression program to speed up the backup process.

- **Incremental Backup**: The script checks for existing backups and performs an incremental backup, removing unnecessary files.

- **Pruning**: Older backups are automatically pruned, and only the latest backup is retained.

## Prerequisites

- Ensure that pigz and tar are installed on your system.

## Contributing

Feel free to contribute to the improvement of this script by submitting issues or pull requests.
