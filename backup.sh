#! /bin/bash

# Copyright 2021 Gagarine Yaikhom (MIT License)

#do_verbose="--verbose"
do_verbose=""

if [[ $# == 0 ]]; then
    echo "USAGE:"
    echo ""
    echo "  backup.sh path-to-backup [target-folder]"
    echo ""
    echo "ARGUMENTS:"
    echo ""
    echo "1)  path-to-backup: (required)"
    echo "    Source folder which you wish to backup."
    echo ""
    echo "2)  target-folder: (optional)"
    echo "    Target folder where backup files should be saved."
    echo "    If unspecified, current directory is used."
    exit
else
    source_folder=${1}
    if [[ $# == 2 ]]; then
	target_folder=${2}
    else
	target_folder=`pwd`
    fi
fi
echo "Will backup source folder: ${source_folder}"
echo "Backup files target folder: ${target_folder}"

# Prepare backup filename suffix. This allows us to use the same
# target folder to store all back files. The suffix is derived from
# the source folder and suffixes all of the backup filenames.
#
# NOTE:
# This may not work for really complicated names.
# This will not work with Windows.
backup_suffix=`echo ${source_folder} | sed -e "s/^\///g" -e "s/\/$//g" -e "s/\//_/g"`
echo ${backup_suffix}

# Take full backup every month. This happens only when you run backup
# for the first time that month. All subsequent runs will produce an
# incremental backup.
datetime_full=`date +"%Y_%m"`

# Take incremental backup every day (multiple times if needed).
# Each incremental backup is time stamped to the second.
datetime_inc=`date +"%Y_%m_%d_%H_%M_%S"`

# The incremental backup manifest filename for the month.  Notice the
# separator, '__'. This is used during recovery to search for
# incremental and full backups.
inc_manifest_file="${datetime_full}__${backup_suffix}.snar"

# Change to target folder, where the backups will be stored.
old_directory=`pwd`
cd ${target_folder}

# Check if the manifest file exists. If yes, carry out an incremental
# backup; otherwise take a full backup, as this is the first day in
# the month that we are running a backup. This allows us to be
# flexible when we run the full backup, rather than specifying a
# specific day of the month. However, since a manifest is maintained
# for each month, we must automatically detect when a month starts.
if test -f "${inc_manifest_file}"; then
    echo "Incremental backup manifest exists;"
    echo "Will run incremental backup..."
    backup_file="${datetime_inc}__${backup_suffix}.tar.bz2"
else
    echo "Incremental backup manifest does not exists;"
    echo "Will run full backup..."
    backup_file="${datetime_full}__${backup_suffix}.tar.bz2"
fi

tar ${do_verbose} --create --bzip2 \
    --preserve-permissions \
    --listed-incremental=${inc_manifest_file} \
    --file=${backup_file} \
    ${source_folder}

cd ${old_directory}

echo "All done..."
