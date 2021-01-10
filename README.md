# A simple backup and restore using `tar`

This project contains a pair of scripts, `backup.sh` and `restore.sh`, for a simple backup and restore of files and folders. 

## Backup

The `backup.sh` script has the following features:

* Backs up contents of a specified source path.
* Creates full backup for each month if none already exists.
* If full backup for month already exists, automatically creates an incremental backup for that month.
* Option to specify target folder for storing backup files.
* Generates separate timestamped backup files.
* Generates non-conflicting filenames for different backup source paths.
* File access permissions are preserved.

```
    USAGE:

       backup.sh path-to-backup [target-folder]

    ARGUMENTS:

    1)  path-to-backup: (required)
        Source folder which you wish to backup.

    2)  target-folder: (optional)
        Target folder where backup files should be saved.
        If unspecified, current directory is used.
```

## Restore

The `restore.sh` script has the following features:

* Restores files and folders from existing backup files.
* Option to specify a full backup file for restoration
    * This will simply restore files in that full backup.
* Option to specify an incremental backup file for restoration.
    * Automatically restores all backup files from month's full backup upto and including the specified incremental backup file. All intermediate incremental backup files are sequentially applied in the correct order.
* Option to specify target folder for storing restored files.

```
    USAGE:

      restore.sh backup-file [target-folder]

    ARGUMENTS:

    1)  backup-file: (required)
        Full or incremental backup file (with full path).
        This is the state you wish to restore upto.

    2)  target-folder: (optional)
        Target folder where restored files should be saved.
        If unspecified, current directory is used.
```

## Example backup usage

```
backup.sh /home/homer/folder_one /home/homer/backups
```
Let's say Homer ran the script at 10:30pm on 12 January 2021, this will create a full backup file named `2021_01__home_homer_folder_one.tar.bz2` inside `/home/homer/backups` (assuming this is the first time Homer is running backup for the month of January of 2021 for the folder `/home/homer/folder_one`).

Now, assume Homer makes few changes to the files and folders in `/home/homer/folder_one` and runs the script again at 11:30pm on 12 January 2021, this will instead create an incremental backup file `2021_01_12_23_30__home_homer_folder_one.tar.bz2`

If Homer runs the command, say, at 11:40pm on 12 January 2021 for a different folder, say, `/home/homer/folder_two` as follows:

```
backup.sh /home/homer/folder_two /home/homer/backups
```

Even though we already ran the `backup.sh` script twice for this month, we are running it for the first time for `/home/homer/folder_two`. Hence, this will create a full backup file named `2021_01__home_homer_folder_two.tar.bz2`. This way, it generates non-conflicting backup files for different source folders. This makes it easy to store backup files for different source folders inside the same backup folder.

Now, let's say Homer didn't run the script for the next two days (maybe he forgot to run the script, or he didn't make any changes worth backing up), and then two days later, say, he makes few changes to both folders and runs the script twice on 15 January 2021 as follows:

```
backup.sh /home/homer/folder_two /home/homer/backups
```

Assuming Homer ran the script at, say, 09:20am of 15 January 2021, this will create an incremental backup since a full backup was generated on 12 January 2021 named `2021_01__home_homer_folder_two.tar.bz2` for that month. The generated incremental backup file will have the filename `2021_01_15_09_20__home_homer_folder_two.tar.bz2`.

Let's say he ran the second time at 10:30am for folder `/home/homer/folder_one` as follows.

```
backup.sh /home/homer/folder_two /home/homer/backups
```

This will create an incremental backup file since we already have a full backup for January, which was create on 12 January 2021, named `2021_01__home_homer_folder_one.tar.bz2`. Since the incremental backup files are timestamped, the new incremental backup file will have the name `2021_01_15_10_30__home_homer_folder_one.tar.bz2`. This will therefore follow `2021_01_12_23_30__home_homer_folder_one.tar.bz2` in lexicographical ordering, the incremental backup generated on 12 January 2021. Thus, the encoded timestamps provides us with a means to order the incremental backups correctly.

Thus, after this run completes, the contents of the target folder `/home/homer/backups` will have the following backup files:

```
2021_01__home_homer_folder_one.tar.bz2
2021_01_12_23_30__home_homer_folder_one.tar.bz2
2021_01_15_10_30__home_homer_folder_one.tar.bz2
2021_01__home_homer_folder_two.tar.bz2
2021_01_15_09_20__home_homer_folder_two.tar.bz2
```

### Rationale

We prefix the filenames with date and time so that it is easy to delete old backup files, which will be clumsy if the date and time were encoded within, for instance, say as `home_homer_folder_two__2021_01_15_09_20.tar.bz2`. By making the date and time a prefix of fixed length, we can detect both whether a backup file is a full backup, `2021_01__`, or an incremental backup `2021_01_12_23_30__`. Note the double '`_`'.

## Example restore usage

Let's say we wish to restore contents of folder `/home/homer/folder_one` that was backed up on the 12th of January 2021 at 11:30pm, and store the restored files to the target folder `/home/homer/restores`. We will run the command as follows:

```
restore.sh /home/homer/backups/2021_01_12_23_30__home_homer_folder_one.tar.bz2 /home/homer/restores
```

This will first restore the full backup for that month, which is `2021_01__home_homer_folder_one.tar.bz2`. Then, it will restore changes to the extracted folder by applying incremental changes saved in `2021_01_12_23_30__home_homer_folder_one.tar.bz2`.

What if we had specified the 15th January 2021 backup taken at 10:30am instead?

```
restore.sh /home/homer/backups/2021_01_15_10_30__home_homer_folder_one.tar.bz2 /home/homer/restores
```

In that case, this will first restore the full backup for that month, using `2021_01__home_homer_folder_one.tar.bz2`. Then, using the timestamp encoded in the filename, the incremental backup `2021_01_12_23_30__home_homer_folder_one.tar.bz2` will be applied first, followed by the incremental backup file `2021_01_15_10_30__home_homer_folder_one.tar.bz2`. In other words, all of the incremental backups following the full backup for that month are applied upto and including the specified incremental backup file.

## History

I wrote this for personal use. Most of the backup solutions feel too complicated, and I do not trust them. All I wanted to do was backup my git repositories from time to time from the command line, and don't require a complicated backup solution. Since this uses the tried and tested `tar`, I know I can recover the files without requiring re-installation of complicated backup solutions. Of course, for more complicated backup and restore scenarios these simple scripts may not be suitable.

END OF DOCUMENT