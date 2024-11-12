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
logfile='/root/tape_backups/'`date +"%Y-%m-%d_%H-%M"`'_tape_backup_notes.txt'
tapeContentList='/root/tape_backups/'`date +"%Y-%m-%d_%H-%M"`'_tape_backup_content.txt'
tarCreateOptions='-c --blocking-factor=2048'
tarReadOptions='-t -v --blocking-factor=2048'
# tarCompressProgramAndOptions='pigz -7 -r'
tarCompressProgramAndOptions=''
pipeTarToDd='n'
ejectTapeAtWriteEnd='y'
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
echo "started: $0 $@"
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
sg_read_attr ${tapeDrive} | grep 'Medium serial number\|MiB' || exit -1
echo

echo "rewind ${tapeDrive}"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} status )
echo

fullSizeInGigaByte=0; for lineInGigaByte in `du -s -BG $@ | awk '{ print $1 }' | sed 's/G$//'`; do let fullSizeInGigaByte=${fullSizeInGigaByte}+${lineInGigaByte}; done
if [ "${tarCompressProgramAndOptions}" != "" ]
then
	echo "write the COMPRESSED content of ${fullSizeInGigaByte} UNCOMPRESSED gigabytes (and some more) to the tape drive"
	echo "write the COMPRESSED content of ${fullSizeInGigaByte} UNCOMPRESSED gigabytes (and some more) to the tape drive" | mail -s "start writing tape" "${mailSendTo}"
	echo
	if [ "$pipeTarToDd" = 'y' ]
	then
		echo "using the following command line to write: tar --use-compress-program="${tarCompressProgramAndOptions}" ${tarCreateOptions} $@ | dd of=${tapeDrive} bs=1M"
		( set -x; date; time tar --use-compress-program="${tarCompressProgramAndOptions}" ${tarCreateOptions} $@ | dd of=${tapeDrive} bs=1M; date )
	else
		echo "using the following command line to write: tar --use-compress-program="${tarCompressProgramAndOptions}" ${tarCreateOptions} -f ${tapeDrive} $@"
		( set -x; date; time tar --use-compress-program="${tarCompressProgramAndOptions}" ${tarCreateOptions} -f ${tapeDrive} $@; date )
	fi
else
	echo "write the UNCOMPRESSED content of ${fullSizeInGigaByte} gigabytes (and some more) to the tape drive"
	echo "write the UNCOMPRESSED content of ${fullSizeInGigaByte} gigabytes (and some more) to the tape drive" | mail -s "start writing tape" "${mailSendTo}"
	echo
	if [ "$pipeTarToDd" = 'y' ]
	then
		echo "using the following command line to write: tar --multi-volume ${tarCreateOptions} $@ | dd of=${tapeDrive} bs=1M"
		( set -x; date; time tar ${tarCreateOptions} $@ | dd of=${tapeDrive} bs=1M; date )
	else
		echo "using the following command line to write: tar --multi-volume ${tarCreateOptions} -f ${tapeDrive} $@"
		( set -x; date; time tar --multi-volume ${tarCreateOptions} -f ${tapeDrive} $@; date )
	fi
fi
echo

( set -x; mt -f ${tapeDrive} status )
echo

echo "read backup and write the list of content to the file '${tapeContentList}'"
echo "read backup and write the list of content to the file '${tapeContentList}'" | mail -s "start reading tape" "${mailSendTo}"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} status )

if [ "$pipeTarToDd" = 'y' ]
then
	if [ "${tarCompressProgramAndOptions}" != "" ]
	then
		echo "using the following command line to read: dd if=${tapeDrive} bs=1M | pigz -d | tar ${tarReadOptions} > "'"'${tapeContentList}'"'
		( set -x; date; time dd if=${tapeDrive} bs=1M | pigz -d | tar ${tarReadOptions} > "${tapeContentList}"; wc -l "${tapeContentList}"; date )
	else
		echo "using the following command line to read: dd if=${tapeDrive} bs=1M | tar ${tarReadOptions} > "'"'${tapeContentList}'"'
		( set -x; date; time dd if=${tapeDrive} bs=1M | tar ${tarReadOptions} > "${tapeContentList}"; wc -l "${tapeContentList}"; date )
	fi
else
	if [ "${tarCompressProgramAndOptions}" != "" ]
	then
		echo "using the following command line to read: dd if=${tapeDrive} bs=1M | pigz -d | tar ${tarReadOptions} >  "'"'${tapeContentList}'"'
		( set -x; date; time dd if=${tapeDrive} bs=1M | pigz -d | tar ${tarReadOptions} > "${tapeContentList}"; wc -l "${tapeContentList}"; date )
	else
		echo "using the following command line to read: tar ${tarReadOptions} -f ${tapeDrive} > "${tapeContentList}
		( set -x; date; time tar ${tarReadOptions} -f ${tapeDrive} > "${tapeContentList}"; wc -l "${tapeContentList}"; date )
	fi
fi

echo

echo "write the list of the content to the tape drive"
( set -x; mt -f ${tapeDrive} rewind )
( set -x; mt -f ${tapeDrive} fsf 1 )
( set -x; mt -f ${tapeDrive} status )
if [ "$pipeTarToDd" = 'y' ]
then
	echo 'using the following command line to write: tar '${tarCreateOptions}' "'${tapeContentList}'" | dd of='${tapeDrive}' bs=1M'
	( set -x; date; tar ${tarCreateOptions} "${tapeContentList}" | dd of=${tapeDrive} bs=1M; date )
else
	echo 'using the following command line to write: tar '${tarCreateOptions}' -f '${tapeDrive}' "'${tapeContentList}'"'
	( set -x; date; tar ${tarCreateOptions} -f ${tapeDrive} "${tapeContentList}"; date )
fi
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

(set -x; bzip2 -9 ${tapeContentList})
echo
echo "The backup could be finished now. Please read '${tapeContentList}.bz2' for possible content of the backup on the tape and check the file '${logfile}' ."
echo
if [ "${ejectTapeAtWriteEnd}" = 'y' ]
then
	(set -x; mt -f ${tapeDrive} eject)
	echo
fi
date
echo
cat "${logfile}" | mail -s "tape backup finished" "${mailSendTo}"

exit 0
