#!/bin/bash

### BEGIN INIT INFO
# Provides:          virtual_maschines
# Required-Start:    $syslog vboxdrv $network
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start an stop virtual machine on VirtualBox
# Description:       Allows to start and stop configured virtual machines 
#                    by starting or stopping the system.
### END INIT INFO

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

case "$1" in

  start)

    # start vm1 
    (set -x; /bin/su user1 -c "/usr/bin/VBoxManage startvm --type headless {11111111-2222-3333-4444-555555555555}")

    # start vm2
    (set -x; /bin/su user2 -c "/usr/bin/VBoxManage startvm --type headless {66666666-7777-8888-9999-aaaaaaaaaaaa}")

  ;;

  stop)

    # stop vm1 
    (set -x; /bin/su user1 -c "/usr/bin/vboxmanage controlvm {11111111-2222-3333-4444-555555555555} acpipowerbutton")

    # start vm2
    (set -x; /bin/su user2 -c "/usr/bin/vboxmanage controlvm {66666666-7777-8888-9999-aaaaaaaaaaaa} acpipowerbutton")

    (set -x; sleep 60)

  ;;

  status)

    # for all users
    for user in $(getent passwd | awk -F ':' '{ print $1 }')
    do 
      VirtualBoxConfigDirectoryOfTheUser=`getent passwd | grep "^${user}:" | awk -F ':' '{ print $6 "/.config/VirtualBox" }'`
      if [ -d $VirtualBoxConfigDirectoryOfTheUser ]
      then
        for machines in `/bin/su $user -c 'VBoxManage list vms'`
        do
          echo 'existing virtual '${machines}' of user' $user
        done
        for machines in `/bin/su $user -c 'VBoxManage list runningvms'`
        do
          echo 'running machines '${machines}' of user' $user
        done
      fi
    done

	;;

  StopAndBackupAll)

    # stop all running maschines
    echo -e "\nSTOPPING MACHINES ...\n"
    $0 stop

    # backup all virtual machines
    echo -e "\nBACKUP MACHINES ...\n"
    backupDir='/system_backups/backups_virtualbox'
    chmod 1777 ${backupDir} || exit -1

    # for all users, backup existing virtual maschines
    for user in $(getent passwd | awk -F ':' '{ print $1 }')
    do 
      VirtualBoxConfigDirectoryOfTheUser=`getent passwd | grep "^${user}:" | awk -F ':' '{ print $6 "/.config/VirtualBox" }'`
      if [ -d $VirtualBoxConfigDirectoryOfTheUser ]
      then
        for machines in `/bin/su $user -c 'VBoxManage list vms' | awk -F '{' '{ print $2 }' | sed 's/}//'`
        do
          echo 'Start backup machine '${machines}' to "'${backupDir}'/", now.'
          dateNow=`date "+%Y-%m-%d_%H-%m-%S"`
          /bin/su $user -c "VBoxManage showvminfo ${machines}" >> ${backupDir}'/'${dateNow}'_information_'${machines}'.txt'
          script=${backupDir}'/backup_script_'${dateNow}'.sh'
          backupPathAndFile=${backupDir}'/'${dateNow}'_backup_'${machines}'.ova'
          echo '#!/bin/bash' > $script
          echo 'set -x' >> $script
          echo '/usr/bin/vboxmanage export '{$machines}' --output '${backupPathAndFile} >> $script
          echo 'chmod 600 '${backupPathAndFile} >> $script
          echo 'ls -l '${backupPathAndFile} >> $script
          echo 'exit 0' >> $script
          chmod 755 $script
          echo; echo 'Starting the following backup script in 5 seconds ...'
          echo; cat $script; echo; sleep 5
          /bin/su $user -c "${script}"
          rm "$script"
        done
      fi
    done


    # start maschines
    echo -e "\nSTARTING MACHINES ...\n"
    (set -x; sleep 10)
    $0 start

   ;;

  *)

    echo "usage: $0 [start|stop|status|StopAndBackupAll]"

	;;

esac

IFS=$OIFS
exit 0
