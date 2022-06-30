#!/bin/bash
#
# use the commercial command ovftool to export virtual machines as *.ova
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

if [ -z "$2" ]
then
    echo
    echo "ERROR USAGE: $0 'LOGIN[:PASSWORT]' '/path/to/the/vm' '/path/to/backup.ova'"
    echo
    echo "      Use >>$0 'LOGIN[:PASSWORT]' '/'<< in loops to find the path to the machines"
    echo "      Write '%20' instead of each ' ' in path or the name of the virtual machine."
    echo
    exit -1
fi

OVFTOOL="/Applications/VMware Fusion.app/Contents/Library/VMware OVF Tool/ovftool"

set -x
time caffeinate -i "$OVFTOOL" --noSSLVerify vi://${1}@esx.example.org${2} ${3}
set +x

if [ -n "$3" ]
then
	du -sh ${3}
fi

exit 0
