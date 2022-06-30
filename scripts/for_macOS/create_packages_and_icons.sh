#!/bin/bash
#
# create packages of all software in this directory with preinstall and postinstall scripts and the short version string from the app or (if missing) the current date as a string
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


########################################


# go to the directory of the script
dirname=`dirname $0`
cd $dirname

# set the file separator
OIFS=$IFS
IFS=$'\n'

# the name of the temporaery script (do not overwrite this in the config file)
SCRIPTFILE="/tmp/tmp_"`date +%s`"_create_pkg.sh"

# read the global settings for all Applications or files in the same directory
DEFAULTCONFIGFILE="./create_packages_and_icons.config"
if [ -f "$DEFAULTCONFIGFILE" ]; then . "$DEFAULTCONFIGFILE"; else echo "ERROR BY READING FILE: $DEFAULTCONFIGFILE"; exit -1; fi

########################################


# create the directories for the new packages
echo;
echo "Create the directories for the new packages and icons."
mkdir -p $PKGPATH || ( echo "ERROR: unable to create the directory: $PKGPATH"; exit -1 )
mkdir -p $ICONPATH || ( echo "ERROR: unable to create the directory: $ICONPATH"; exit -1 )


########################################


# START the uninstall script
echo -e "#!/bin/bash\n\necho" > $UNINSTALLSCRIPT
echo -e 'echo "### COMMANDS FOR DELETING APPLICATIONS: ###" > "/tmp/uninstall_'$DIRNAMEAPP'.sh"' >> $UNINSTALLSCRIPT
echo -e 'echo >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"\n' >> $UNINSTALLSCRIPT
echo -e 'echo set -x >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"\n' >> $UNINSTALLSCRIPT
echo -e 'echo >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"\n' >> $UNINSTALLSCRIPT


########################################


# try if the last package creating was broken
if [ -d './creating_package_tmp' ]
then
    echo -e "\nWARNING: Found and move back applications from the last creation process...\n\n"
    mv -i -v ./creating_package_tmp/* ./
    rm -f -v ./creating_package_tmp/.DS_Store
    rmdir "./creating_package_tmp/" || (echo "Error by deleting folder: ./creating_package_tmp/"; sleep 3600)
    echo -e "\nContinue in 20 seconds ...\n\n"
    sleep 20
fi


########################################

echo 'Start creating of '`ls -1 | grep -i -v "^Applications\|^\_\|.DS_Store$\|.dmg$\|.pkg$\|.mpkg$" | wc -l`' packages in 3 seconds.'
sleep 3

# create new temp script with the commands to create packages
echo
echo "***********************************************************************************"
echo
SCRIPTCONTENT='echo "create package(s) ..."'

# for (nearly) all files of the current directory define the script lines to create the package and find icon
for i in $(ls -1 | grep -i -v "^Applications\|^\_\|.DS_Store$\|.dmg$\|.pkg$\|.mpkg$")
do

    # mask the character '"' in names like: 'Example" name.app'
    i=`echo "$i" | sed 's/"/\\\"/g'`

    # searching for the App
    APPDIR=`find $dirname/$i | grep '.app$' | awk '{ print length " " $0 }' | sort -n | cut -d " " -f2- | head -n 1`
    if [ "$APPDIR" != "" ]; then echo -e "\n     found the following \*.app: $APPDIR"; fi

    # read the global settings for all Applications or files in the same directory, again (nessesary, if an App change some settings before)
    if [ -f "$DEFAULTCONFIGFILE" ]; then . "$DEFAULTCONFIGFILE"; else echo "ERROR BY READING FILE: $DEFAULTCONFIGFILE"; exit -1; fi

    # OVERWRITE (SOME) UPPER CONFIGURATIONS, IF A CONFIG FILE WAS FOUND ON './_build_files/name.app/create.cfg' OR './_build_files/name/create.cfg'
    if [ -f "./_build_files/$i/create.cfg" ]
    then
        CONFIGFILE="./_build_files/$i/create.cfg"
    else
        CONFIGFILE="./_build_files/`echo $i | sed 's/.app//'`/create.cfg";
    fi
    if [ -f "${CONFIGFILE}" ];
    then
        echo -e "     FOUND AND READ THE FOLLOWING CONFIG FILE TO OVERWRITE SETTINGS: ${CONFIGFILE} ***"
        source "${CONFIGFILE}"
        echo "*** START CONFIG ***"
        cat "${CONFIGFILE}" | grep -v '^#\|^$'
        echo -e "*** END CONFIG ***"
    else
        echo "     Do not found special config file '"$CONFIGFILE"'. Using the default values, now."
    fi

    #
    # define an version number for the package
    #
    if [ $CONTENTONLY = 'y' ]
    then
        # normally changing will be in a subdirectory here -> use the current date version number
        DEFAULTVERSION=$(date '+0.0.%Y.%m.%d')
    else
        # for Apps without a version number -> use the date of the last change of the software (folder)
        DEFAULTVERSION=$(date -r `stat -f "%m" "$i"` '+0.0.%Y.%m.%d')
    fi
    INFOFILE=''; APPSHORTVERSION=''
    # if Info.plist exists, try to fetch the short version number
    if [ -f "${APPDIR}/Contents/Info.plist" ]
    then
        INFOFILE="${APPDIR}/Contents/Info.plist"
        APPSHORTVERSION=`defaults read "${APPDIR}/Contents/Info.plist" CFBundleShortVersionString 2> /dev/null | grep '.' | awk -F ' ' '{ print $1 }'`
    fi
    # if the version number ends with '.' add the number '0' on the end
    if [ `echo ${APPSHORTVERSION: -1}` = "." ] 2> /dev/null; then APPSHORTVERSION=$APPSHORTVERSION'0'; fi
    # use the version number from the Info.plist or the default version number
    if [ "$APPSHORTVERSION" = "" ]
        then PKGVERSION=$DEFAULTVERSION 
        else PKGVERSION=$APPSHORTVERSION
    fi
    # overwrite the version number, if set in configuration
	if [ "$VERSION" != '' ]
		then PKGVERSION="$VERSION"
	fi

    # write the version of the new package and get the version of the last created package
    echo "$i:$PKGVERSION" >> $currentPackageVersionFilePath
    lastVersionNumber=`grep "^$i:" $lastPackageVersionFilePath 2> /dev/null | awk -F ':' '{ print $2 }' 2> /dev/null`  

    #
    ## if $createOnlyNewPackages='y' and there is no new version, SKIP the next steps for this package
    #

    if [ "$createOnlyNewPackages" != 'y' ] || [ "$PKGVERSION" != "$lastVersionNumber" ]
    then

        echo -e "\n*** CREATING PACKAGE FOR THE SOFTWARE $i ... ***\n"
    
        # define the last part of the package identifier (the full package identifier must be unique and without special letters)
        SOFTWAREID=`echo $i | sed "s/ //g" | sed "s/[^a-zA-Z0-9]/_/g" | sed "s/.app$//"`        

        # create the directory for the pre and post install scripts
        mkdir -p "$PKGPATH/_tmp_build_files/$SOFTWAREID" || ( echo "ERROR: unable to create the directory: '$PKGPATH/_tmp_build_files/$SOFTWAREID'"; exit -1 )
    
        #
        ## create the preinstall script
        #
        if [ -f "_build_files/$i/preinstall" ]
        then
            # use the existing preinstall script
            cp "_build_files/$i/preinstall" "$PKGPATH/_tmp_build_files/$SOFTWAREID/preinstall"
            chmod 755 "$PKGPATH/_tmp_build_files/$SOFTWAREID/preinstall"
        else
            # create a new preinstall script
            PRIS="$PKGPATH/_tmp_build_files/$SOFTWAREID/preinstall"
            echo '#!/bin/bash' > $PRIS
            echo 'set -x' >> $PRIS
            echo 'echo "*** START INSTALLATION OF: '$PREFIX_IDENTIFIER$SOFTWAREID' ***"' >> $PRIS
            echo '/bin/date' >> $PRIS
            # exit with 0 to say the installer that the scripts runs correctly
            echo 'exit 0' >> $PRIS
            chmod 755 $PRIS
        fi
        
        #
        ## create the postinstall script
        #
        if [ -f "_build_files/$i/postinstall" ]
        then
            # use the existing postinstall script
            cp "_build_files/$i/postinstall" "$PKGPATH/_tmp_build_files/$SOFTWAREID/postinstall"
            chmod 755 "$PKGPATH/_tmp_build_files/$SOFTWAREID/postinstall"
        else
            # create a new postinstall script
            POIS="$PKGPATH/_tmp_build_files/$SOFTWAREID/postinstall"
            echo '#!/bin/bash' > $POIS
            echo 'set -x' >> $POIS
            if [ $CONTENTONLY = 'n' ];
            then
                # remove the quarantine bits
                echo '/usr/bin/xattr -r -d com.apple.quarantine "'$TARGETDIR/$i'"' >> $POIS
                # if possible set the new owner of the software
                if [ "$SETUSERANDGROUP" = 'y' ]
                then
                    # if the file $USERANDGROUPFILE, read it to set the owner and group
                    echo 'if [ -f "'$USERANDGROUPFILE'" ]; then . "'$USERANDGROUPFILE'"; fi' >> $POIS
                    # if not, use the owner and group from the installer command
                    echo 'if [ -z "$USERANDGROUP" ]'  >> $POIS
                    echo '  then IUSER=`ps awux | grep -i "/Installer" | grep -v "grep -i" | head -n 1'" | awk -F ' ' '{ print \$1 }'"'`'  >> $POIS
                    echo '  if [ -n "$IUSER" ]; then USERANDGROUP="${IUSER}:staff"; fi; fi' >> $POIS
                    # if defined, change the owner to the new written files 
                    echo 'if [ -n "$USERANDGROUP" ]; then /usr/sbin/chown -R $USERANDGROUP "'$TARGETDIR/$i'"; fi' >> $POIS
                fi
            else
                set -x
                # make the attributs writable and delete the quarantine bits
                chmod -R u+w $i
                /usr/bin/xattr -r -d com.apple.quarantine $i
                set +x
            fi
            echo '/bin/date' >> $POIS
            echo 'echo "*** END INSTALLATION OF: '$PREFIX_IDENTIFIER$SOFTWAREID' ***"' >> $POIS
            # exit with 0 to say the installer that the scripts runs correctly
            echo 'exit 0'  >> $POIS
            chmod 755 $POIS
        fi

        #    
        ## EINTRAG ZUM ERSTELLEN DES PAKETES NUN SCHREIBEN
        #
    
        # create or define the directory with the content of the new package (all files have to be in one directory)
        PKGNAME=`echo "$i" | sed s/.app$//`
        if [ $CONTENTONLY != 'y' ]
        then
            CONTENTDIR='creating_package_tmp'
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo 'mkdir "'$CONTENTDIR'" || ( echo "ERROR: MAYBE OLD FILES IN: '$CONTENTDIR' ???"; sleep 10000 )'`
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo 'mv "'$i'" "'${CONTENTDIR}'/"'`
        else
            CONTENTDIR=$i
        fi
    
        MOREOPT=''
    
        if [ "${DONOTRELOCATE}" = 'y' ]
        then        
            # analyse the content and write a plist file
            PLISTFILE="$PKGPATH/_tmp_build_files/$SOFTWAREID/components.plist"
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "pkgbuild --analyze --root '"$CONTENTDIR"' '"$PLISTFILE"'"`
            
            # patch the plist file to define, the content can NOT be written to an different path
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "awk '/<key>BundleIsRelocatable<\/key>/{ print; getline; "'$'"0=\"<false/>\" }1' $PLISTFILE > ${PLISTFILE}.patched"`
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "( set -x; diff ${PLISTFILE}.patched $PLISTFILE )"`
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "( set -x; mv ${PLISTFILE}.patched $PLISTFILE )"`
            
            # define, that the plist file have to read, by creating the package
            MOREOPT=${MOREOPT}' --component-plist "'$PLISTFILE'" '
        fi
        
        # write the line to create the package
        SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "( set -x; pkgbuild ${MOREOPT} --scripts '$PKGPATH/_tmp_build_files/$SOFTWAREID' --identifier '${PREFIX_IDENTIFIER}${SOFTWAREID}' --version '$PKGVERSION' --root '$CONTENTDIR' --install-location '$TARGETDIR' \"${PKGPATH}/${PKGNAME}.pkg\" )"`
    
        # remove the files back from the temporary directory
        if [ $CONTENTONLY != 'y' ]
        then
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo 'mv "'${CONTENTDIR}/${i}'" "'$i'"'`
            SCRIPTCONTENT=`echo "${SCRIPTCONTENT}"; echo "rmdir '$CONTENTDIR'"`
        fi
        
        # search and build the ICON
        PLISTFILE=''; ICNSNAME='/NOT_EXISTS.dummy';
        if [ -f "$APPDIR/Contents/Info.plist" ]
        then
            PLISTFILE="$APPDIR/Contents/Info.plist"
            # search for the file name of the icns file
            ICNSNAME="$APPDIR/Contents/Resources/"`/usr/libexec/PlistBuddy -c 'print CFBundleIconFile' "$PLISTFILE"`;
            ICONNAME=`basename $APPDIR | sed 's/.app$/.png/g'`; 
            # patch the name of the icns file (somtimes the suffix .icns is missing in the Info.plist)
            if [ -f "$ICNSNAME.icns" ]; then ICNSNAME="$ICNSNAME.icns"; fi
            # create the png ICON from the icns file
            if [ -f "$ICNSNAME" ]; then echo "     create new image '$ICONPATH/$ICONNAME' from icon '$ICNSNAME'"; /usr/bin/sips -s format png --out "$ICONPATH/$ICONNAME" "$ICNSNAME" > /dev/null; fi
        fi
        
        # write an uninstall script
        echo 'echo sudo rm -rfv \"'$TARGETDIR'/'$i'\" >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"' >> $UNINSTALLSCRIPT
        echo 'echo sudo pkgutil --forget "'$PREFIX_IDENTIFIER$SOFTWAREID'" >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"' >> $UNINSTALLSCRIPT
        echo -e 'echo >> "/tmp/uninstall_'$DIRNAMEAPP'.sh"\n' >> $UNINSTALLSCRIPT

    else

        echo -e "\n*** SKIP CREATING PACKAGE FOR THE SOFTWARE $i , NOW. THE OLD PACKAGE SHOULD HAVE BE THE SAME VERSION NUMBER. CHANGE OR REMOVE $lastPackageVersionFilePath TO RECREATE IT, OR CHANGE THE CONFIG FILE. ***\n"

    fi

done

echo "${SCRIPTCONTENT}" > $SCRIPTFILE

mv $currentPackageVersionFilePath $lastPackageVersionFilePath

########################################


# END the uninstall script
echo 'cat "/tmp/uninstall_'$DIRNAMEAPP'.sh"' >> $UNINSTALLSCRIPT
echo -e 'echo\n' >> $UNINSTALLSCRIPT
echo 'echo -n "Should I execute the upper commands to remove the software ? (y/n) : "' >> $UNINSTALLSCRIPT
echo 'read USERINPUT' >> $UNINSTALLSCRIPT
echo 'echo' >> $UNINSTALLSCRIPT
echo 'if [ ! $USERINPUT ]; then USERINPUT="n"; fi' >> $UNINSTALLSCRIPT
echo 'if [ $USERINPUT != "y" ]' >> $UNINSTALLSCRIPT
echo 'then' >> $UNINSTALLSCRIPT
echo '   echo -e "Stop the operation here, at your choice. Nothing deleted.\n"' >> $UNINSTALLSCRIPT
echo '   exit -1' >> $UNINSTALLSCRIPT
echo 'fi' >> $UNINSTALLSCRIPT
echo -e 'echo\n' >> $UNINSTALLSCRIPT
echo -e '/bin/bash "/tmp/uninstall_'$DIRNAMEAPP'.sh"\n' >> $UNINSTALLSCRIPT
echo 'exit 0' >> $UNINSTALLSCRIPT

chmod 755 $UNINSTALLSCRIPT


########################################


# show the temporary script
echo
echo "Start creating packages in 10 seconds. Last chance to break this script ('$SCRIPTFILE') ... "
echo
echo '+++ START SCRIPT CONTENT +++'
cat $SCRIPTFILE | grep -v 'set -x'
echo '+++ END SCRIPT CONTENT +++'
echo -e "\n********************\n\n"

sleep 10

# start the temporary script and CREATE THE PACKAGES
echo
bash $SCRIPTFILE


########################################


# create an install script for all packages of the directory
echo -e -n '#!/bin/bash\nOIFS=$IFS\n'"IFS='" > $INSTALLSCRIPT
echo -e -n '\n' >> $INSTALLSCRIPT
echo -e -n "'\n" >> $INSTALLSCRIPT
echo 'set -x' >> $INSTALLSCRIPT
echo '' >> $INSTALLSCRIPT
echo 'DIRNAME=`dirname $0`' >> $INSTALLSCRIPT
echo 'cd $DIRNAME' >> $INSTALLSCRIPT
echo '' >> $INSTALLSCRIPT
echo -e "for i in *.pkg\ndo\n   sudo installer -verbose -pkg \"\$i\" -target /\ndone" >> $INSTALLSCRIPT
echo '' >> $INSTALLSCRIPT
if [ "$SETUSERANDGROUP" = 'y' ]
then
    echo 'set +x' >> $INSTALLSCRIPT
    echo 'if [ -f "'$USERANDGROUPFILE'" ]' >> $INSTALLSCRIPT
    echo 'then' >> $INSTALLSCRIPT
    echo '   echo "Found config file '$USERANDGROUPFILE' and read it for the new owner of the Application."' >> $INSTALLSCRIPT
    echo '   . "'$USERANDGROUPFILE'"' >> $INSTALLSCRIPT
    echo 'else ' >> $INSTALLSCRIPT
    echo '   if [ $1 ]' >> $INSTALLSCRIPT
    echo '      then' >> $INSTALLSCRIPT
    echo '         USERANDGROUP=$1;' >> $INSTALLSCRIPT
    echo '      else' >> $INSTALLSCRIPT
    echo '         echo -n "Please type the login and/or group name which should be the NEW OWNER (e.g. mylogin or root:wheel): "' >> $INSTALLSCRIPT
    echo '         read USERANDGROUP' >> $INSTALLSCRIPT
    echo '   fi' >> $INSTALLSCRIPT
    echo 'fi' >> $INSTALLSCRIPT
    echo "TARGETDIR=$TARGETDIR" >> $INSTALLSCRIPT
    echo 'set -x' >> $INSTALLSCRIPT
    echo -e "for i in *.pkg\ndo\n   sudo chown -R "'$USERANDGROUP "$TARGETDIR/`echo $i | sed '"'"s/.pkg/.app/g"'"'`"'"\ndone" >> $INSTALLSCRIPT
    echo 'set +x' >> $INSTALLSCRIPT
fi
chmod 755 $INSTALLSCRIPT


########################################


# remove the temporary files (preinstall and postinstall script and the component plist)
if [ "$REMOVETEMPBUILDFILES" = 'y' ]
then
    echo -e "\nRemoving the following temporaery files, now:\n"
    rm -rfv "$PKGPATH/_tmp_build_files"
fi

# Notes for the user
echo
echo "If there was no error, the new packages should be in '$PKGPATH' now."
echo
echo 'Some notes:'
echo
echo '* the script "_install_all.sh" will be install all packages of the directory'
echo
echo '* please have a look to "/var/log/install.log" for debugging after installation'

if [ "$SETUSERANDGROUP" = 'y' ]
then
    echo
    echo '* Please create the following line into "'$USERANDGROUPFILE'" to set the owner and group, by installing the package(s):'
    echo
    echo '        USERANDGROUP="mylogin:staff"   # this file (with this variable) will be used for new files during some installations'
fi

echo
echo '* Use the following command to find your new installedn package(s):'
echo
echo '        for i in `pkgutil --pkgs | grep "'$PREFIX_IDENTIFIER'"`; do pkgutil -v q --pkg-info $i; done'
echo
echo '     The information about your package will be stored in "/var/db/receipts/'$PREFIX_IDENTIFIER'.*". Use the following commands to read this files:'
echo
echo '        lsbom -fls /var/db/receipts/'$PREFIX_IDENTIFIER'PROGRAM_NAME.bom          # to get the list of files of the package'
echo '        defaults read /var/db/receipts/'$PREFIX_IDENTIFIER'PROGRAM_NAME.plist     # to get some other package information'
echo

# set the file separator back to the old values
IFS=$OIFS

exit 0
