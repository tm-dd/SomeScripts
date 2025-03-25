#!/bin/bash
#
# create and delete ZFS snapshots
#
# Copyright (c) 2025 tm-dd (Thomas Mueller)
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

# settings
prefixSnapshots='snapshot_'
keepOnlyLastHourlyBackups=24
keepOnlyLastDailyBackups=31
keepOnlyLastMonthlyBackups=12
keepOnlyLastYearlyBackups=1

# temp files
tempFileListOfAllSnapshots="/tmp/ListOfAllSnapshots_from_PID_$$.txt"
tempFileListOfFirstYearlySnapshots="/tmp/ListOfFirstYearlySnapshots_from_PID_$$.txt"
tempFileListOfFirstMonthlySnapshots="/tmp/ListOfMonthlyMonthlySnapshots_from_PID_$$.txt"
tempFileListOfFirstDailySnapshots="/tmp/ListOfFirstDailySnapshots_from_PID_$$.txt"
tempFileListOfFirstHourlySnapshots="/tmp/ListOfFirstHourlySnapshots_from_PID_$$.txt"
tempFileListOfKeepingSnapshots="/tmp/ListOfKeepingSnapshots_from_PID_$$.txt"
tempFileListOfAllOldSnapshots="/tmp/ListOfAllOldSnapshots_from_PID_$$.txt"
shortTimeTempFile="/tmp/temp_from_PID_$$.txt"

# run only as root
if [ -z "$1" ]
then
	echo "ERROR - USAGE: $0 nameOfZfsVolumen"
	exit -1
fi

# get names of the pool and volume
zfsvolumename="$1"
zfspool=`echo "${zfsvolumename}" | awk -F '/' '{ print $1 }'`

# set time values
day=`date +%d`
month=`date +%m`
year=`date +%Y`
hour=`date +%H`

# build name parts of the snapshot(s)
firstPartOfName="${zfsvolumename}@${prefixSnapshots}"
newSnapshotname="${firstPartOfName}${year}-${month}-${day}_${hour}hr"

# print settings
echo 
echo "*** current settings: ***"
echo
echo "keep all snapshots of the last                 $keepOnlyLastHourlyBackups hour(s)"
echo "keep one snapshot of every day in the last     $keepOnlyLastDailyBackups day(s)"
echo "keep one snapshot of every month in the last   $keepOnlyLastMonthlyBackups month(s)"
echo "keep one snapshot of every year in the last    $keepOnlyLastYearlyBackups year(s)"
echo "the name of the newest snapshot should be      $newSnapshotname"
echo

# create the list of all snapshots with the prefix
/usr/sbin/zfs list -t snapshot $1 | grep "$1" | sort | awk '{ print $1 }' > "${tempFileListOfAllSnapshots}"
echo
echo "*** list of all snapshots of the given volume name: ***"
echo
cat "${tempFileListOfAllSnapshots}"
echo

# create new snapshot if not exists before
echo
if [ -z "`grep ${newSnapshotname} ${tempFileListOfAllSnapshots}`" ]
then
	echo "*** create new snapshot: ***"
	echo
	( set -x; zfs snapshot "${newSnapshotname}" )
else
	echo "*** skip recreating the snapshot ${newSnapshotname} for the current time ***"
fi
echo

# create the list yearly snapshots to keep
echo -n '' > $tempFileListOfFirstYearlySnapshots
for j in `seq $(($year-$keepOnlyLastYearlyBackups+1)) $year`
do
	oldesBackupOfTheYear=`grep "${firstPartOfName}${j}" "${tempFileListOfAllSnapshots}" | head -n 1`
	# echo "* checked snapshots of the year $j and found the snapshot: ${oldesBackupOfTheYear} *"
	if [ "" != "$oldesBackupOfTheYear" ]; then echo "${oldesBackupOfTheYear}" >> $tempFileListOfFirstYearlySnapshots; fi
done
echo
echo "*** keep this snapshots for the yearly snapshots: ***"
echo
cat "$tempFileListOfFirstYearlySnapshots"
echo

# create the list monthly snapshots to keep
echo -n '' > $tempFileListOfFirstMonthlySnapshots
for m in `seq 0 $(($keepOnlyLastMonthlyBackups-1))`
do
	timePartOfName=`date --date "$m months ago" "+%Y-%m"`
	oldesBackupOfTheMonth=`grep "${firstPartOfName}${timePartOfName}" "${tempFileListOfAllSnapshots}" | head -n 1`
	# echo "* checked snapshots of the month $timePartOfName and found the snapshot: ${oldesBackupOfTheMonth} *"
	if [ "" != "$oldesBackupOfTheMonth" ]; then echo "${oldesBackupOfTheMonth}" >> $tempFileListOfFirstMonthlySnapshots; fi
done
echo
echo "*** keep this snapshots for the monthly snapshots: ***"
echo
cat "$tempFileListOfFirstMonthlySnapshots"
echo

# create the list daily snapshots to keep
echo -n '' > $tempFileListOfFirstDailySnapshots
for d in `seq 0 $(($keepOnlyLastDailyBackups-1))`
do
	timePartOfName=`date --date "$d days ago" "+%Y-%m-%d"`
	oldesBackupOfTheDay=`grep "${firstPartOfName}${timePartOfName}" "${tempFileListOfAllSnapshots}" | head -n 1`
	# echo "* checked snapshots of the day $timePartOfName and found the snapshot: ${oldesBackupOfTheDay} *"
	if [ "" != "$oldesBackupOfTheDay" ]; then echo "${oldesBackupOfTheDay}" >> $tempFileListOfFirstDailySnapshots; fi
done
echo
echo "*** keep this snapshots for the daily snapshots: ***"
echo
cat "$tempFileListOfFirstDailySnapshots"
echo

# create the list hourly snapshots to keep
echo -n '' > $tempFileListOfFirstHourlySnapshots
for h in `seq 0 $(($keepOnlyLastHourlyBackups-1))`
do
	timePartOfName=`date --date "$h hours ago" "+%Y-%m-%d_%Hhr"`
	oldesBackupOfTheHour=`grep "${firstPartOfName}${timePartOfName}" "${tempFileListOfAllSnapshots}" | head -n 1`
	# echo "* checked snapshots of the date and hour $timePartOfName and found the snapshot: ${oldesBackupOfTheHour} *"
	if [ "" != "$oldesBackupOfTheHour" ]; then echo "${oldesBackupOfTheHour}" >> $tempFileListOfFirstHourlySnapshots; fi
done
echo
echo "*** keep this snapshots for the hourly snapshots: ***"
echo
cat "$tempFileListOfFirstHourlySnapshots"
echo

# create the list of all keeping Snapshots
cat "$tempFileListOfFirstYearlySnapshots" "$tempFileListOfFirstMonthlySnapshots" "$tempFileListOfFirstDailySnapshots" "$tempFileListOfFirstHourlySnapshots" | sort | uniq > "$tempFileListOfKeepingSnapshots"
echo
echo "*** found the following snapshots to KEEP: ***"
echo
cat "${tempFileListOfKeepingSnapshots}"
echo

# create the list of old Snapshots
cp -a "${tempFileListOfAllSnapshots}" "${tempFileListOfAllOldSnapshots}"
for s in `cat "${tempFileListOfKeepingSnapshots}"`
do
	grep -v "$s" "${tempFileListOfAllOldSnapshots}" > "${shortTimeTempFile}"
	mv "${shortTimeTempFile}" "${tempFileListOfAllOldSnapshots}"
done
echo
echo "*** found the following snapshots to DELETE in a few seconds (LAST CHANCE to stop the removing): ***"
echo
cat "${tempFileListOfAllOldSnapshots}"
echo
sleep 20

# remove old snapshots
echo
echo "*** remove old snapshots: ***"
echo
for s in `cat "${tempFileListOfAllOldSnapshots}"`
do
	( set -x; zfs destroy $s )
done
echo

# show all snapshots of the volume
echo
echo "*** all snapshots of the volume: ***"
echo
( set -x; /usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}" )
echo

# show the space of the whole pool
echo
echo "*** show space of the whole pool: ***"
echo
( set -x; /usr/sbin/zfs list -o space -r "${zfspool}" )
echo

# remove temporary files
echo
echo "*** remove temporary files and exit ***"
echo
rm -v $tempFileListOfAllSnapshots
rm -v $tempFileListOfFirstYearlySnapshots
rm -v $tempFileListOfFirstMonthlySnapshots
rm -v $tempFileListOfFirstDailySnapshots
rm -v $tempFileListOfFirstHourlySnapshots
rm -v $tempFileListOfKeepingSnapshots
rm -v $tempFileListOfAllOldSnapshots
echo

# exit now
exit 0
