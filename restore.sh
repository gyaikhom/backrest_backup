#! /bin/bash

# Copyright 2021 Gagarine Yaikhom (MIT License)

#do_verbose="--verbose"
do_verbose=""

if [ $# -eq 0 ]; then
    echo "USAGE:"
    echo ""
    echo "  restore.sh backup-file [target-folder]"
    echo ""
    echo "ARGUMENTS:"
    echo ""
    echo "1)  backup-file: (required)"
    echo "    Full or incremental backup file (with full path)."
    echo "    This is the state you wish to restore upto."
    echo ""
    echo "2)  target-folder: (optional)"
    echo "    Target folder where restored files should be saved."
    echo "    If unspecified, current directory is used."
    exit
else
    backup_file_path=`realpath ${1}`
    if [ $# -eq 2 ]; then
	target_folder=${2}
    else
	target_folder=`pwd`
    fi
fi

echo "Supplied backup file: ${backup_file_path}"
if [[ ! -e ${backup_file_path} ]]; then
    echo "Backup file does not exists"
    echo "Restore cancelled..."
    exit
else
    if [[ ! -f ${backup_file_path} ]]; then
	echo "Backup file is not a file"
	echo "Restore cancelled..."
	exit
    else
	if [[ ! -r ${backup_file_path} ]]; then
	    echo "Backup file is unreadable"
	    echo "Restore cancelled..."
	    exit
	fi
    fi
fi

target_folder=`realpath ${target_folder}`
echo "Supplied target folder: ${target_folder}"
if [[ ! -e ${target_folder} ]]; then
    echo "Target folder does not exists"
    echo "Restore cancelled..."
    exit
else
    if [[ ! -d ${target_folder} ]]; then
	echo "Target folder is not a directory"
	echo "Restore cancelled..."
	exit
    else
	if [[ ! -w ${target_folder} ]]; then
	    echo "Target folder is not writable"
	    echo "Restore cancelled..."
	    exit
	fi
    fi
fi

# Extract the backup folder from the supplied filepath so
# we can find the remaining full backup (if supplied file
# is incremental backup file). Restoration will begin at
# the first full backup of the month. The fact that there
# is an incremental backup means that there is a full
# backup (assuming nothing was deleted).
backups_folder=`dirname ${backup_file_path}`
final_backup_file=`basename ${backup_file_path}`

# Check if the requested restore point is a full backup
# If yes, simply restore that file and we are done.
# Otherwise, we must find the start point and end point
# and process all of the intermediate points.
if [[ ${final_backup_file} =~ ^[0-9_]{7}__ ]]; then
    echo "Will restore a full backup from ${backup_file_path}"
    echo ""
    echo "Do you wish to continue with restoration? (type number)"
    select yn in "Yes" "No"; do
	case $yn in
            No ) echo "Restoration cancelled"; exit;;
            Yes ) tar ${do_verbose} --extract --bzip2 \
		      --directory=${target_folder} \
		      --preserve-permissions \
		      --listed-incremental=/dev/null \
		      --file=${backup_file_path};
		  break;
	esac
    done
else
    echo "Restore upto a supplied incremental backup"
    echo "Will search for full and other incremental backups at"
    echo ${backups_folder}

    # Generate the full backup for that month
    full_backup_file=`echo ${final_backup_file} | sed -e "s/.\{12\}__/__/g"`
    
    # Generate the incremental backup file pattern
    inc_pattern=`echo ${final_backup_file} | sed -e "s/.\{12\}__/_*__/g"`

    # Pattern for incremental backup files with path
    inc_file_pattern_with_path="${backups_folder}/${inc_pattern}"
    
    # List all of the incremental files in the order they will be
    # restored starting with the most recent full backup
    echo "Files to be restoration in sequence:"
    echo "${full_backup_file}"
    for f in `ls ${inc_file_pattern_with_path}`; do
	inc_file=`basename ${f}`
	if [[ ${inc_file} == ${final_backup_file} ]]; then
	    break;
	fi
	echo "${inc_file}"
    done
    echo "${final_backup_file}"
    echo ""
    echo "Do you wish to continue with restoration? (type number)"
    select yn in "Yes" "No"; do
	case $yn in
            No ) echo "Restoration cancelled"; exit;;
            Yes ) echo "Restoring ${full_backup_file}";
		  full_backup_file="${backups_folder}/${full_backup_file}"
		  tar ${do_verbose} --extract --bzip2 \
		      --directory=${target_folder} \
		      --preserve-permissions \
		      --listed-incremental=/dev/null \
		      --file=${full_backup_file};
		  for f in `ls ${inc_file_pattern_with_path}`; do
		      inc_file=`basename ${f}`
		      echo "Restoring ${inc_file}"
		      tar ${do_verbose} --extract --bzip2 \
			  --directory=${target_folder} \
			  --preserve-permissions \
			  --listed-incremental=/dev/null \
			  --file=${f};
		      if [[ ${inc_file} == ${final_backup_file} ]]; then
			  break;
		      fi
		  done
		  break;
	esac
    done
fi

echo "All done..."
