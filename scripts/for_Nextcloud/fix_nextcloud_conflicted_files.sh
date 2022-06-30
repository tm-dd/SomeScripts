#!/bin/bash
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

OIFS=$IFS
IFS=$'\n'

if [ -z "$1" ]; then echo -e "\nUSAGE: $0 PATH_TO_CLOUD_DIRECTORY\n"; exit -1; fi

FILES=`find "$1" | grep 'onflicted copy '`

if [ "" != "${FILES}" ]
then
	echo -e "\n*** FOUND the following files: \n\n${FILES}"
	echo -e "\n*** Please check and run the following commands (if correct):\n"
	for oldName in `echo "${FILES}"`
	do
		newName=`echo "${oldName}" | sed 's/Conflicted copy /Old copy /' | sed 's/conflicted copy /old copy /'`
		echo 'mv "'${oldName}'" "'${newName}'"'
	done
else
	echo -e "*** Could not found a 'conflicted copy'.\n"
fi

echo

IFS=$OIFS
exit 0
