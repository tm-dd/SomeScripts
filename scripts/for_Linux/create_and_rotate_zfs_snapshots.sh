#!/bin/bash
#
# create and rotate snapshots
# please run this script only one a day
#
# Copyright (c) 2022 tm-dd (Thomas Mueller)
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

# create (rename) snapshot lastWeekday
/usr/sbin/zfs destroy "${zfsvolumename}@lastWeekday"
/usr/sbin/zfs rename "${zfsvolumename}@today" "${zfsvolumename}@lastWeekday"

# create snapshot today
/usr/sbin/zfs snapshot "${zfsvolumename}@today"

# on Monday to
if [ "`date +%u`" -eq "1" ]
then
	# create snapshot lastMonday
	/usr/sbin/zfs destroy "${zfsvolumename}@lastMonday"
	/usr/sbin/zfs rename "${zfsvolumename}@monday" "${zfsvolumename}@lastMonday"

	# create snapshot monday
	/usr/sbin/zfs snapshot "${zfsvolumename}@monday"
fi

# on the first day of a month do
if [ "`date +%d`" -eq "01" ]
then
	# create snapshot startOfPenultimateMonth
	/usr/sbin/zfs destroy "${zfsvolumename}@startOfPenultimateMonth"
	/usr/sbin/zfs rename "${zfsvolumename}@startOfLastMonth" "${zfsvolumename}@startOfPenultimateMonth"

	# create snapshot startOfLastMonth
	/usr/sbin/zfs rename "${zfsvolumename}@startOfMonth" "${zfsvolumename}@startOfLastMonth"

	# create snapshot startOfMonth
	/usr/sbin/zfs snapshot "${zfsvolumename}@startOfMonth"
fi

date
echo
/usr/sbin/zfs list -r -t snapshot -o name,creation,space "${zfsvolumename}"
echo
/usr/sbin/zfs list -o space -r "${zfspool}"

exit 0
