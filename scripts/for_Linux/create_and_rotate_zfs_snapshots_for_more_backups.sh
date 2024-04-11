#!/bin/bash
#
# by Thomas Mueller
#
# create and rotate snapshots
# please run this script only once a day
#
# NO WARRANTY
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

if [ "${numberOfTheDayOfTheWeek}" -eq "1" ]
# on monday start a new weekly snapshot and a snapshot for the monday
then

	# delete the oldest snapshot, if exists
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

# delete and create new snapshot for the weekday
if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@${nameOfDay} 2> /dev/null`" ]
then 
	( set -x; /usr/sbin/zfs destroy "${zfsvolumename}@${nameOfDay}" )
fi
( set -x; /usr/sbin/zfs snapshot "${zfsvolumename}@${nameOfDay}" )


# on the second day of a month do
if [ "${numberOfDayInMonth}" -eq "02" ]
then
	
	# delete snapshot
	if [ -n "`/usr/sbin/zfs list -t snapshot ${zfsvolumename}@month-${numberOfMonth} 2> /dev/null`" ]
	then
		( set -x; /usr/sbin/zfs destroy "${zfsvolumename}@month-${numberOfMonth}" )
	fi

	# create snapshot for this month
	( set -x; /usr/sbin/zfs snapshot "${zfsvolumename}@month-${numberOfMonth}" )

fi

echo
( set -x; /usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}" )

echo
( set -x; /usr/sbin/zfs list -o space -r "${zfspool}" )

echo
date

exit 0
