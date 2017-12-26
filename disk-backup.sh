#!/bin/bash
###----------------------------------------------------------------------------
### Script Name:    disk-daily.sh
### Description:    Runs Daily Disk Snapshots
###----------------------------------------------------------------------------

## Source in necessary files
SCRIPT_DIR=/usr/local/scripts/systems/backups-disk
source ~/.bash_profile
source $SCRIPT_DIR/inc/vars.sh
source $SCRIPT_DIR/inc/funcs.sh

## Main Script Function
main ()
{
    while IFS= read -r line
    do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ "$line" = "" ]] && continue
        echo ${line} | while IFS=: read -r HostName Disks
        do
           #
           # If the disk name is * - mean backup all disk
           # Otherwise we go to process a list of disks spacified after host with comma delited
           # Example:
           # All disk for instance1 with retention days equal 3
           #     instance1:*:3
           #
           # List of disk for for instance1 with retention days equal 3
           #     instance1:disk-1:3,disk-2:3
           #
           if [[ ${Disks:0:1} == '*' ]]
           then
                # Extracting a retention days from config if exist
                RETENTION_DAYS=$( echo "${Disks}" | cut -d ":" -f 2 )

                if [ "${RETENTION_DAYS}" == "${Disks}" ]
                then
                   # Retention days was not provided in config
                   RETENTION_DAYS=${DAYS_RETENTION}
                   logMsg INFO Using default retention days ${DAYS_RETENTION} for all disks in $HostName
                else
                   # Retention days was provided in config
                   RETENTION_DAYS=${RETENTION_DAYS}
                   logMsg INOF Retention days for all disk in $HostName is $RETENTION_DAYS
                fi
                logMsg INFO Backup of all disks for ${HostName} | tee -a $LOG_FILE
                gcd-backup_all_disk "${HostName}" $RETENTION_DAYS
                gcd-delete_all_snap "${HostName}"
           		logMsg INFO "Exit code all disk $?"
            else

                # The configration provided to do backup for list of disk
                logMsg INFO "Backup following disks for ${HostName} host:" | tee -a $LOG_FILE
                logMsg INFO "${Disks}" | tee -a $LOG_FILE
                gcd-backup_list_disk "${HostName}" "${Disks}"
                gcd-delete_all_snap "${HostName}"
	        logMsg INFO  "Exit code list $?"
		logMsg INFO |  tee -a $LOG_FILE
            fi
        done
    done < ${CONFIG_FILE}
    logMsg "INFO" "Backup creation is completed"|tee -a $LOG_FILE
}

## Run MAIN Function
main "$@"
logMsg "INFO" "Backup creation is completed"|tee -a $LOG_FILE
emailIt "COMPLETE: Google DWH ${1} backup" "${LOG_FILE}"
