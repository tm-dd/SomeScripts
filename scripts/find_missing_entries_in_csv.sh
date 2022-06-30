#!/bin/bash
#
# Script to find missing numbers in two csv files.
#
# 	An example:
#
#		left.csv:
#			       1,a,b
#			       2,c,d
#			       5,e,f
#
#		right.csv:
#			       2,h,i
#			       4,c,d
#			       3,j,k
#
# 	... should give the note, that the numbers 1 and 5 are missing in right.csv and the numbers 3 and 4 are missing in left.csv .
#
# Copyright (c) 2020 tm-dd (Thomas Mueller)
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

if [ "$2" == "" ]
then
	echo "USAGE       : $0 left.csv right.csv [ --debugLeft | --debugRight ]"
	echo "AT FIRST    : This script searching for all values in the first colum of the left.csv for the same value in right.csv."
	echo "AT SECOUND  : This script searching for all values in the first colum of the right.csv for the same value in left.csv."
	echo "PLEASE NOTE : Put the searching values in the first colums and use the single character ',' to seperate the colums."
	exit -1
fi

leftFile=$1
rightFile=$2

for i in `cat $leftFile | awk -F ',' '{ print $1 }'`
do
	found=`grep $i $rightFile`
	if [ "$found" == "" ]
	then
		echo "NOT FOUND NUMBER $i IN RIGHT FILE."
		if [ "$3" == "--debugLeft" ]
		then
			echo -n "   - grep $i right_file -> "; grep $i $rightFile | tr '\n' ' '; echo "<-   "
			echo -n "   - grep $i left_file  -> "; grep $i $leftFile | tr '\n' ' '; echo "<-   "
		fi
	fi
done

echo -e "\n\n++++\n\n"

for i in `cat $rightFile | awk -F ',' '{ print $1 }'`
do
	found=`grep $i $leftFile`
	if [ "$found" == "" ]
	then
		echo "NOT FOUND NUMBER $i IN LEFT FILE."
		if [ "$3" == "--debugRight" ]
		then
			echo -n "   - grep $i left_file  -> "; grep $i $leftFile | tr '\n' ' '; echo "<-   "
			echo -n "   - grep $i right_file -> "; grep $i $rightFile | tr '\n' ' '; echo "<-   "
		fi
	fi
done

exit 0
