#!/bin/bash
#
# a basic script to write data to a tape drive
#
# Copyright (c) 2024 tm-dd (Thomas Mueller)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

#echo "search drives with auto rewind"
#( set -x; ls -l /dev/st* | grep tape )
#echo

#echo "search drives without auto rewind"
#( set -x; ls -l /dev/nst* | grep tape )
#echo

tapeDrive=/dev/nst0
logfile='/root/tape_backups/'`date +"%Y-%m-%d"`'_tape_backup_notes.txt'
tapeContentList='/root/tape_backups/'`date +"%Y-%m-%d"`'_tape_backup_content.txt'
tarCreateOptions='--multi-volume -cf'
mailSendTo='root'

# write all stdout and stderr also into a file
exec > >(tee "${logfile}") 2>&1

if [ -z "${1}" ]
then
	echo
	echo "try to write some data to ${tapeDrive}"
	echo "USAGE: $0 tobackup1 [tobackup2] [...]"
	echo
	exit -1
fi

if [ -z "`pwd | grep .zfs/snapshot`" ] && [ -d ".zfs/snapshot" ]
then 
	echo "Maybe better use a subfolder of .zfs/snapshot/ for reading to a backup ?"
	( echo "chance to break"; sleep 10; echo "continue without break" );
fi

echo
date
echo
(set -x; pwd)
echo

if [ -z "`which sg_read_attr`" ]
then 
	echo "install software to read the serial number"
	( set -x; apt install sg3-utils )
	echo
fi

echo "tape on ${tapeDrive}"
( set -x; sg_read_attr ${tapeDrive} || exit -1 )
echo

echo "rewind ${tapeDrive}"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} status )
echo

fullSizeInGigaByte=0; for lineInGigaByte in `du -s -BG $@ | awk '{ print $1 }' | sed 's/G$//'`; do let fullSizeInGigaByte=${fullSizeInGigaByte}+${lineInGigaByte}; done
echo "write ${fullSizeInGigaByte} gigabytes (and some more) to the tape drive"
echo "write ${fullSizeInGigaByte} gigabytes (and some more) to the tape drive" | mail -s "start writing tape" "${mailSendTo}"
echo
( set -x; date; time tar ${tarCreateOptions} ${tapeDrive} $@; date )
echo

( set -x; mt -f ${tapeDrive} status )
echo

echo "read backup and write the list of content to the file '${tapeContentList}'"
echo "read backup and write the list of content to the file '${tapeContentList}'" | mail -s "start reading tape" "${mailSendTo}"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} status )
( set -x; date; time tar -tvf ${tapeDrive} > "${tapeContentList}"; wc -l "${tapeContentList}"; date )
echo

echo "write the list of the content to the tape drive"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} fsf 1 )
( set -x; mt -f ${tapeDrive} status )
( set -x; date; time tar -cf ${tapeDrive} "${tapeContentList}"; date )
echo 

( set -x; mt -f ${tapeDrive} status )
echo

echo "rewind ${tapeDrive}"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} status )
echo

echo "tape on ${tapeDrive}"
sg_read_attr ${tapeDrive} | grep 'Medium serial number\|MiB'
echo

echo
(set -x; bzip2 -9 ${tapeContentList})
echo
echo "The backup could be finished now. Please read '${tapeContentList}'.bz2 for possible content of the backup on the tape and check the file '${logfile}' ."
echo
(set -x; mt -f ${tapeDrive} eject)
echo
date
echo
cat "${logfile}" | mail -s "tape backup finished" "${mailSendTo}"

exit 0
