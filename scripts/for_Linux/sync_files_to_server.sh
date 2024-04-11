#!/bin/bash
#
# by Thomas Mueller
#
# NO WARRANTY
#

# settings
localPathsToBackup='/home /system_backups'
localSshfsMountPoint='/tmp/sshfsmount_backup'
backupFolder="${localSshfsMountPoint}/`hostname`/backups/"
sftpLogin='sftp-'"`hostname`"
sftpServer='target.example.tld'
sshfsServerTarget="${sftpLogin}@${sftpServer}:/"
runBashScriptBeforeSync=''
runBashScriptAfterSync=''
rsyncOptions='-a --no-owner --no-group --delete'

echo
date
echo

# if nessesary, mount the sshfs target
if [ -z "`/bin/mount | grep \"${sshfsServerTarget}\"`" ]
then
	set -x
	echo -e "mounting sshfs ...\n"
	mkdir -p "${localSshfsMountPoint}" && /usr/bin/sshfs "${sshfsServerTarget}" "${localSshfsMountPoint}"
	sleep 3
	set +x
fi

# check sshfs mount point (again)
if [ -z "`/bin/mount | grep \"^$sshfsServerTarget on \"`" ]
then
	echo "ERROR: The backup directory '$sshfsServerTarget' for the server `hostname` could not mounted."
	echo
	date
	df -h
	exit -1
fi

# create backup directory, if nessesary
( set -x; mkdir -p "${backupFolder}" && ls -la "${backupFolder}" )
echo

# sync the folders
cd "${backupFolder}" && (

	date > './last_sync.txt'

	if [ -n "${runBashScriptBeforeSync}" ]; then ( set -x; /bin/bash "${runBashScriptBeforeSync}" ); echo; fi
	sleep 3

	part=1
	for toBackup in ${localPathsToBackup}
	do
		( set -x; mkdir -p "./part_${part}" )
		( set -x; pwd )
		echo "try to run 'rsync ${rsyncOptions} "${toBackup}" "./part_${part}/"  >> ./last_sync.txt 2>&1'" >> './last_sync.txt'
		( set -x; rsync ${rsyncOptions} "${toBackup}" "./part_${part}/" >> './last_sync.txt' 2>&1 )
		part=$((${part}+1))
		echo
	done 
	if [ -n "${runBashScriptAfterSync}" ]; then ( set -x; /bin/bash "${runBashScriptAfterSync}" ); echo; fi

) || (

	echo
	echo "ERROR: BACKUP DIRECTORY '${localSshfsMountPoint}' NOT EXISTS."
	echo
	exit -1

)

( set -x; df -h "${localSshfsMountPoint}" )
echo
date
echo

exit 0
