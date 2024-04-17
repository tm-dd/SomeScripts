#!/bin/bash
#
# create and rotate snapshots and keep more snapshots
#
# please note: run this script only one a day and check the disk space often, because snapshots can take a lot of space
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

if [ -z "$1" ]
then
	echo "ERROR - USAGE: $0 nameOfZfsVolumen"
	exit -1
fi

zfsvolumename="$1"
zfspool=`echo "${zfsvolumename}" | awk -F '/' '{ print $1 }'`

numberOfDayInMonth=`date +%d`
numberOfTheDayOfTheWeek=`date +%u`
namesOfWeekDays=(sunday monday tuesday wednesday thursday friday saturday sunday)
nameOfDay="${namesOfWeekDays[${numberOfTheDayOfTheWeek}]}"
numberOfMonth=`date +%m`
keepMaxNumberOfMonth=3

if [ "${numberOfTheDayOfTheWeek}" -eq "1" ]
# on monday start a new weekly snapshot and a snapshot for the monday
then

	# delete the oldest weekly snapshot, if exists
	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@monday3WeeksAgo 2> /dev/null`" ]
	then 
		( set -x; /usr/sbin/zfs destroy "${zfsvolumename}@monday3WeeksAgo" )
	fi

	#
	# rename existing snapshots
	#
	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@monday2WeeksAgo 2> /dev/null`" ]
	then 
		( set -x; /usr/sbin/zfs rename "${zfsvolumename}@monday2WeeksAgo" "${zfsvolumename}@monday3WeeksAgo" )
	fi

	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@monday1WeekAgo 2> /dev/null`" ]
	then 
		( set -x; /usr/sbin/zfs rename "${zfsvolumename}@monday1WeekAgo" "${zfsvolumename}@monday2WeeksAgo" )
	fi

	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@monday 2> /dev/null`" ]
	then 
		( set -x; /usr/sbin/zfs rename "${zfsvolumename}@monday" "${zfsvolumename}@monday1WeekAgo" )
	fi

fi

# delete and create a new snapshot for the weekday
if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@${nameOfDay} 2> /dev/null`" ]
then 

	# delete snapshot, if the name still exists
	( set -x; /usr/sbin/zfs destroy "${zfsvolumename}@${nameOfDay}" )

fi

# create the new snapshot for the weekday
( set -x; /usr/sbin/zfs snapshot "${zfsvolumename}@${nameOfDay}" )


# on the second day of a month do
if [ "${numberOfDayInMonth}" -eq "02" ]
then
	
	# delete snapshot, if the name still exists
	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@month-${numberOfMonth} 2> /dev/null`" ]
	then
		( set -x; /usr/sbin/zfs destroy "${zfsvolumename}@month-${numberOfMonth}" )
	fi

	# create snapshot for this month
	( set -x; /usr/sbin/zfs snapshot "${zfsvolumename}@month-${numberOfMonth}" )

fi

# build the number of monthly snapshots
numberOfMonthlySnapshots=`/usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}" -s creation | grep "${zfsvolumename}@month-" | wc -l`

# if too much old monthly snapshots exists, remove the oldes monthly snapshot
if [ "${numberOfMonthlySnapshots}" -gt "${keepMaxNumberOfMonth}" ]
then
	nameOfSnapshotToDelete=`/usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}" -s creation | grep "${zfsvolumename}@month-" | head -n 1 | awk '{ print $1 }'`
	( set -x; /usr/sbin/zfs destroy "${nameOfSnapshotToDelete}" )
fi

# show all snapshots of the volume
echo
( set -x; /usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}" )

# show the space of the whole pool
echo
( set -x; /usr/sbin/zfs list -o space -r "${zfspool}" )

echo
date

exit 0
