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

# please read:
# https://github.com/Lord-Kamina/SwiftDefaultApps
# https://aporlebeke.wordpress.com/2020/07/16/configuring-a-macs-default-apps-for-different-file-types/
# https://en.wikipedia.org/wiki/Uniform_Type_Identifier


# please download the necessary software from https://github.com/Lord-Kamina/SwiftDefaultApps
SWDA='/Applications/SwiftDefaultApps/swda'
if [ ! -e "${SWDA}" ]; then echo "ERROR: missing '${SWDA}'"; exit -1; fi

# set default program
if [ -e "$2" ]
then
	
	TYPE=`mdls -name kMDItemContentType "$1" | awk -F '"' '{ print $2 }'`
	CURAPP=`${SWDA} getHandler --UTI "${TYPE}"`
	NEWAPP="$2"
	(set -x; ${SWDA} getHandler --UTI "${TYPE}"; ${SWDA} setHandler --app "${NEWAPP}" --UTI "${TYPE}")
	echo -e "\n   file: '$1' \n   type: ${TYPE} \n   old app : ${CURAPP}\n   new app : ${NEWAPP}\n"
	exit 0
fi

# get default programm
if [ -f "$1" ]
then
	
	TYPE=`mdls -name kMDItemContentType "$1" | awk -F '"' '{ print $2 }'`
	CURAPP=`${SWDA} getHandler --UTI "${TYPE}"`
	echo -e "\n   file: '$1' \n   type: ${TYPE} \n   app : ${CURAPP}\n"
	exit 0
fi

# function to change the type
forThisFileTypeUseTheProgram ()
{
	EXT="$1"
	TYPE="$2"
	NEWAPP="$3"
	CURAPP=`${SWDA} getHandler --UTI "${TYPE}"`
	if [ -e "$NEWAPP" ]
	then
		${SWDA} setHandler --app "${NEWAPP}" --UTI "${TYPE}" > /dev/null
		NEWAPP=`${SWDA} getHandler --UTI ${TYPE}`
		echo "   default application for file type '$TYPE' (suffix '$EXT') from '$CURAPP' to '$NEWAPP' changed" 
	else
		echo "   ERROR: Couldn't change file type '$TYPE' from '$CURAPP' to '$NEWAPP', because '$NEWAPP' doesn't exists."
	fi 
}

# change some default programs

echo
echo "Press ENTER to try to change the following default Applications or press [ctrl] and [C] to skip this: "
echo
grep "^   forThisFileTypeUseTheProgram '" $0 | grep -v '^grep '
echo
read

##    forThisFileTypeUseTheProgram 'SUFFIX' 'FILE TYPE' 'APPPATH' ##

   forThisFileTypeUseTheProgram 'tex'  'org.tug.tex' '/Applications/TeX/TeXShop.app'
   forThisFileTypeUseTheProgram 'djvu' 'com.lizardtech.djvu' '/Applications/DjView/DjView.app'
   forThisFileTypeUseTheProgram 'key'  'com.apple.iwork.keynote.sffkey' '/Applications/Keynote.app'

   forThisFileTypeUseTheProgram 'gz'   'org.gnu.gnu-zip-archive' '/Applications/Keka.app'
   forThisFileTypeUseTheProgram 'zip'  'public.zip-archive' '/Applications/Keka.app'
   forThisFileTypeUseTheProgram 'bz2'  'public.bzip2-archive' '/Applications/Keka.app'
   forThisFileTypeUseTheProgram 'exe'  'com.microsoft.windows-executable' '/Applications/Keka.app'
   forThisFileTypeUseTheProgram 'tar'  'public.tar-archive' '/Applications/Keka.app'
   forThisFileTypeUseTheProgram '7z'   'org.7-zip.7-zip-archive' '/Applications/Keka.app'

   forThisFileTypeUseTheProgram 'm4v'  'com.apple.m4v-video' '/Applications/VLC.app'
   forThisFileTypeUseTheProgram 'mp3'  'public.mp3' '/Applications/VLC.app'
   forThisFileTypeUseTheProgram 'mts'  'public.avchd-mpeg-2-transport-stream' '/Applications/VLC.app'
   forThisFileTypeUseTheProgram 'mkv'  'org.matroska.mkv' '/Applications/VLC.app'

   forThisFileTypeUseTheProgram 'mov'  'com.apple.quicktime-movie' '/System/Applications/QuickTime Player.app'

   forThisFileTypeUseTheProgram 'pdf'  'com.adobe.pdf' '/System/Applications/Preview.app'
   forThisFileTypeUseTheProgram 'jpeg' 'public.jpeg' '/System/Applications/Preview.app'
   forThisFileTypeUseTheProgram 'heic' 'public.heic' '/System/Applications/Preview.app'


   forThisFileTypeUseTheProgram 'sxi'  'org.openoffice.presentation' '/Applications/LibreOffice.app'
   forThisFileTypeUseTheProgram 'sxc'  'org.openoffice.spreadsheet' '/Applications/LibreOffice.app'
   forThisFileTypeUseTheProgram 'sxw'  'org.openoffice.text' '/Applications/LibreOffice.app'

   forThisFileTypeUseTheProgram 'odp'  'org.oasis-open.opendocument.presentation' '/Applications/LibreOffice.app'
   forThisFileTypeUseTheProgram 'odg'  'org.oasis-open.opendocument.graphics' '/Applications/LibreOffice.app'
   forThisFileTypeUseTheProgram 'odt'  'org.oasis-open.opendocument.text' '/Applications/LibreOffice.app'

   forThisFileTypeUseTheProgram 'doc'  'com.microsoft.word.doc' '/Applications/Microsoft Word.app'
   forThisFileTypeUseTheProgram 'docx' 'org.openxmlformats.wordprocessingml.document' '/Applications/Microsoft Word.app'

   forThisFileTypeUseTheProgram 'xlsx' 'org.openxmlformats.spreadsheetml.sheet' '/Applications/Microsoft Excel.app'

   forThisFileTypeUseTheProgram 'pps'  'com.microsoft.powerpoint.pps' '/Applications/Microsoft PowerPoint.app'
   forThisFileTypeUseTheProgram 'ppt'  'com.microsoft.powerpoint.ppt' '/Applications/Microsoft PowerPoint.app'
   forThisFileTypeUseTheProgram 'pptx' 'com.microsoft.powerpoint.ppt' '/Applications/Microsoft PowerPoint.app'

   forThisFileTypeUseTheProgram 'py'   'public.python-script' '/Applications/PyCharm CE.app'

   forThisFileTypeUseTheProgram 'txt'  'public.plain-text' '/Applications/SubEthaEdit.app'
   forThisFileTypeUseTheProgram 'sh'   'public.shell-script' '/Applications/SubEthaEdit.app'
   forThisFileTypeUseTheProgram 'f'    'public.fortran-source' '/Applications/SubEthaEdit.app'
   forThisFileTypeUseTheProgram 'f90'  'public.fortran-90-source' '/Applications/SubEthaEdit.app'

   forThisFileTypeUseTheProgram 'html' 'public.html' '/Applications/Safari.app'

   forThisFileTypeUseTheProgram 'kdbx' 'dyn.ah62d4rv4ge8003dcta' '/Applications/KeePassXC.app'

echo

exit 0
