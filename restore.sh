#! /bin/bash

# Copyright 2021 Gagarine Yaikhom (MIT License)

#do_verbose="--verbose"
do_verbose=""

if [[ $# == 0 ]]; then
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
    if [[ $# == 2 ]]; then
	target_folder=${2}
    else
	target_folder=`pwd`
    fi
fi

echo "Supplied backup file: ${backup_file_path}"
if [[ ! -e ${backup_file_path} ]]; then
    echo "Backup file does not exists"
    echo "Restoration cancelled..."
    exit
else
    if [[ ! -f ${backup_file_path} ]]; then
	echo "Backup file is not a file"
	echo "Restoration cancelled..."
	exit
    else
	if [[ ! -r ${backup_file_path} ]]; then
	    echo "Backup file is unreadable"
	    echo "Restoration cancelled..."
	    exit
	fi
    fi
fi

target_folder=`realpath ${target_folder}`
echo "Supplied target folder: ${target_folder}"
if [[ ! -e ${target_folder} ]]; then
    echo "Target folder does not exists"
    echo "Restoration cancelled..."
    exit
else
    if [[ ! -d ${target_folder} ]]; then
	echo "Target folder is not a directory"
	echo "Restoration cancelled..."
	exit
    else
	if [[ ! -w ${target_folder} ]]; then
	    echo "Target folder is not writable"
	    echo "Restoration cancelled..."
	    exit
	fi
    fi
fi

# Extract the backup folder name from the supplied filepath so we can
# find the remaining full backup (if supplied file is incremental
# backup file). Restoration will begin at the first full backup of the
# month. The fact that there is an incremental backup (i.e., the
# supplied backup file) means that there is a full backup (assuming
# nothing was deleted since the last full backup).
backups_folder=`dirname ${backup_file_path}`
final_backup_file=`basename ${backup_file_path}`

# Check if the requested restore point is a full backup. If yes,
# simply restore the contents of that file and we are done. Otherwise,
# we must find the start point full backup and all intermediate
# incremental backups until the end point incremental backup, and
# process all of these in the correct sequence to restore upto the
# requested state.
#
# Notice that we use the location of the '__' delimiter in the file
# name to identify full or incremental backup. The regex checks for
# YYYY_MM__ pattern, which is the full backup filename pattern.
if [[ ${final_backup_file} =~ ^[0-9_]{7}__ ]]; then
    echo "Restoring from a full backup file"
    echo ""
    echo "Do you wish to continue with the restoration? (type number)"
    select yn in "Yes" "No"; do
	case $yn in
            No ) echo "Restoration cancelled by user..."; exit;;
            Yes ) tar ${do_verbose} --extract --bzip2 \
		      --directory=${target_folder} \
		      --preserve-permissions \
		      --listed-incremental=/dev/null \
		      --file=${backup_file_path};
		  break;
	esac
    done
else
    echo "Restoring upto an incremental backup"
    echo "Searching for full and intermediate incremental backups in:"
    echo "    ${backups_folder}"

    # Generate the full backup filename for that month. We simply
    # remove the _DD_HH_MM_SS from the incremental backup filename.
    full_backup_file=`echo ${final_backup_file} | sed -e "s/.\{12\}__/__/g"`

    echo "Required full backup file: ${full_backup_file}"
    if [[ ! -e ${full_backup_file} ]]; then
	echo "Full backup file does not exists"
	echo "Restoration cancelled..."
	exit
    else
	if [[ ! -f ${full_backup_file} ]]; then
	    echo "Full backup file is not a file"
	    echo "Restoration cancelled..."
	    exit
	else
	    if [[ ! -r ${full_backup_file} ]]; then
		echo "Full backup file is unreadable"
		echo "Restoration cancelled..."
		exit
	    fi
	fi
    fi
    
    # Generate the incremental backup filename pattern. To do this, we
    # simply remove the _DD_HH_MM_SS from the incremental backup
    # filename, and replace this with a '*' for globbing.
    inc_pattern=`echo ${final_backup_file} | sed -e "s/.\{12\}__/_*__/g"`

    # Incremental backup filename pattern with path prefixed.
    inc_file_pattern_with_path="${backups_folder}/${inc_pattern}"
    
    # List all of the intermediate incremental backup files in the
    # order they will be restored.
    num_intermediates=0;
    echo "Intermediate incremental backup files to be restored in sequence:"
    for f in `ls ${inc_file_pattern_with_path}`; do
	inc_file=`basename ${f}`
	if [[ ${inc_file} == ${final_backup_file} ]]; then
	    break;
	fi

	((num_intermediates++))
	printf "%2d. %s\n" ${num_intermediates} ${inc_file}

	if [[ ! -f ${full_backup_file} ]]; then
	    echo "Incremental backup file is not a file"
	    echo "Restoration cancelled..."
	    exit
	else
	    if [[ ! -r ${full_backup_file} ]]; then
		echo "Incremental backup file is unreadable"
		echo "Restoration cancelled..."
		exit
	    fi
	fi
    done

    echo "Final incremental backup file: ${final_backup_file}"
    echo ""
    echo "Do you wish to continue with the restoration? (type number)"
    select yn in "Yes" "No"; do
	case $yn in
            No ) echo "Restoration cancelled by user..."; exit;;
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
