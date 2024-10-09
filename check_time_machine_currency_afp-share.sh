#!/bin/bash

#   Check Time Machine Currency over AFP-Share
#   Nico Hartung
#   nicohartung1@googlemail.com

#   Thanks for insperetion
#   @jedda (https://github.com/jedda/OSX-Monitoring-Tools/blob/master/check_time_machine_currency.sh)
#   @yesdevnull (https://github.com/yesdevnull/OSX-Monitoring-Tools/blob/master/check_time_machine_currency.sh)

#   v1.2 - 09 October 2024
#   - No indication of "TotalBytesCopied" of the snapshots since new macos.
#   v1.1 - 09 October 2019
#   - New folderstructur since macos catalina.
#   v1.0 - 22 March 2017
#   - Initial release.

#   This script checks the Time Machine SnapshotHistory on a Linux TimeMachine AFP Share (netatalk, sparsebundle) and reports if a backup/snapshot has completed within a number of minutes of the current time.
#   Very useful if you are monitoring client production systems, and want to ensure backups are occurring.

#   Arguments:
#   -w     Warning threshold in minutes
#   -c     Critical threshold in minutes
#   -p     Path to TimeMachine / AFP Share
#   -h     Hostname from Backup-Client

#   Example:
#   ./check_time_machine_currency_afp-share.sh -p /mnt/data/backup/TimeMachine -h hedwig -w 4320 -c 10080

while getopts "w:c:p:h:" opt
    do
        case $opt in
            w ) warnMinutes=$OPTARG;;
            c ) critMinutes=$OPTARG;;
            p ) path=$OPTARG;;
            h ) hostname=$OPTARG;;
        esac
done

if [ "$warnMinutes" == "" ]
then
    echo "ERROR - You must provide a warning threshold with -w!\n"
    exit 3
fi

if [ "$critMinutes" == "" ]
then
    echo "ERROR - You must provide a critical threshold with -c!\n"
    exit 3
fi

if [ "$hostname" == "" ]
then
    echo "ERROR - You must provide a hostname -h!\n"
    exit 3
fi

if [ "$path" == "" ]
then
    echo "ERROR - You must provide a path with -p!\n"
    exit 3
else
    if [ -d "$path/$hostname.sparsebundle" ]; then pathdot=sparsebundle; fi
    if [ -d "$path/$hostname.backupbundle" ]; then pathdot=backupbundle; fi
fi

if [ "$pathdot" == "" ]
then
    echo "ERROR - Not found a sparsebundle or backupbundle folder!\n"
    exit 3
fi

lastBackup=`grep "com.apple.backupd.SnapshotCompletionDate" $path/$hostname.$pathdot/com.apple.TimeMachine.SnapshotHistory.plist -A5 | tail -6`
lastBackupDateString=`echo $lastBackup | grep -E -o "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}"`
lastBackupTotalBytesCopied=`echo $lastBackup | sed 's/^.*<integer>\(.*\)<\/integer>.*$/\1/p'`

if [ "$lastBackupDateString" == "" ]
then
    echo "CRITICAL - Time Machine has not completed a backup on this Mac! (chmod at com.apple.TimeMachine.SnapshotHistory.plist?)\n"
    exit 2
fi

lastBackupDateStringFormat=`echo $lastBackupDateString | sed 's/\(.*\)-/\1 /' | sed 's/.\{2\}$//'`
lastBackupDateUnix=`date -d "$lastBackupDateStringFormat" +"%s"`
lastBackupDate=`date -d @$lastBackupDateUnix +"%Y-%m-%d %H:%M"`
currentDateUnix=`date +%s`

diff=$(($currentDateUnix - $lastBackupDateUnix))
warnSeconds=$(($warnMinutes * 60))
critSeconds=$(($critMinutes * 60))
warnHours=$(($warnMinutes / 60))
critHours=$(($critMinutes / 60))

lastBackupTotalGigaBytesCopied=`echo "scale=2; $lastBackupTotalBytesCopied / 1024 / 1024 / 1024" | bc`

if [ "$diff" -gt "$critSeconds" ]
then
    echo "CRITICAL - Time Machine has not performed any backups since $lastBackupDate (more than $critHours hours)!"
    exit 2
elif [ "$diff" -gt "$warnSeconds" ]
then
    echo "WARNING - Time Machine has not performed any backups since $lastBackupDate (more than $warnHours hours)!"
    exit 1
fi

if [ "$lastBackupDateUnix" != "" ]
then
    if [ "$lastBackupTotalGigaBytesCopied" == "" ]
    then
        echo "OK - Time Machine has performed a backup on $lastBackupDate (less than $warnHours hours)."
    else
        echo "OK - Time Machine has performed a backup on $lastBackupDate (less than $warnHours hours), `echo $lastBackupTotalGigaBytesCopied | awk '{ print $2 }' | sed 's/^\./0\./g'` GB was additionally copied."
    fi
    exit 0
else
    echo "CRITICAL - Could not determine the last backup date for this Mac."
    exit 2
fi