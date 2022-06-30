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

if [ ! "$1" ]; then echo "ERROR USAGE: $0 folder_to_save_as_dmg"; exit -1; fi

FOLDER=`basename "$1"`
NAME=`echo $FOLDER | sed 's/.app$//' | sed 's/  //g' | sed 's/ /_/g'`
TARGET="/Users/$USER/Desktop/CREATED_DMG/$NAME.dmg"

echo "This will create the DMG image $TARGET with the content of the folder '$1'."
(set -x; sleep 5)
# echo "Press ENTER to continue."
# read

cd "$1/.."

set -x
	mkdir -p /Users/$USER/Desktop/CREATED_DMG
	hdiutil create -volname "$NAME" -srcfolder "$FOLDER" -ov -format UDZO -imagekey zlib-level=9 "$TARGET"
	chown -R $USER:staff /Users/$USER/Desktop/CREATED_DMG
set +x

exit 0
