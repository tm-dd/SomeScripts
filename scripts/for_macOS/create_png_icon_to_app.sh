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

ICONPATH="$HOME/Desktop/_icons"

# pruefe ob ein Parameter angegeben wurde
if [ ! "$1" ]
then
    echo "ERROR USAGE: $0 path/to/App.app"
    exit -1
fi

# gehe ins Verzeichnis der App (u.a. um den Namen spaeter zu bilden)
cd "$1"

ICNSNAME="$1/Contents/Resources/"`/usr/libexec/PlistBuddy -c 'print CFBundleIconFile' "$1/Contents/Info.plist"`;

# haenge .icns an den Namen der Datei an, falls noetig 
if [ ! -f "$ICNSNAME" ]
then
    if [ -f "$ICNSNAME.icns" ]
    then ICNSNAME="$ICNSNAME.icns"
    fi
fi

# erstelle ICON-Datei fuer Munki
if [ -f "$ICNSNAME" ]
then
    mkdir -p $ICONPATH
    ICONNAME=`basename $(pwd) | tr '\n' ' ' | sed 's/.app $//g'`'.png';
    rm -f "$ICONPATH/$ICONNAME"
    echo "create new icon: '$ICONPATH/$ICONNAME'"
    /usr/bin/sips -s format png --out "$ICONPATH/$ICONNAME" "$ICNSNAME" > /dev/null
fi

exit 0
