#!/bin/bash -x
###----------------------------------------------------------------------------
### Script Name:    funcs.sh
### Description:    Fuctions for main script
###----------------------------------------------------------------------------

## Function - Log - formating a log output
logMsg()
{
    ts=$(date +"%Y-%m-%d %H:%M:%S")
    LEVEL=$1
    shift
    echo -e "${ts} -- ${LEVEL} -- $@"
}

gcd_run_gcloud_del ()
{
    exit_code=0
    SNAP_NAME=${1}
    logMsg "INFO" "Deleting snapshot ${SNAP_NAME}"
    gcloud compute snapshots delete ${SNAP_NAME} --quiet
    exit_code=$?
    logMsg "INFO" "gcd_run_gcloud_del EXIT CODE $exit_code"
    return $exit_code
}

## Function - Run GCLoud Disk Snapshot
gcd_run_gcloud_snap ()
{
    exit_code=0
    DISK_NAME=$1
    host_zone=$2
    DAYS_RETENTION=$3
    retention_date=$(date -d "+${DAYS_RETENTION} days" "+%Y%m%d")
    logMsg "INFO" "Creating ${SNAP_PREFIX}-${DISK_NAME:0:31} for $DISK_NAME in ${host_zone} retention date ${retention_date}"
    gcloud compute disks snapshot $DISK_NAME --snapshot-names ${SNAP_PREFIX}-${DISK_NAME:0:31} --zone ${host_zone} --quiet
    #gcloud compute snapshots list --filter="labels.retention_date:'201712*'" --uri
    exit_code=$?
    logMsg "INFO" "gcd_run_gcloud_snap EXIT CODE $exit_code"
    if [ $exit_code -eq 0 ]
    then
       gcloud compute snapshots add-labels ${SNAP_PREFIX}-${DISK_NAME:0:31} --labels='retention_date='${retention_date}''
       exit_code=$?
    fi
    return $exit_code
}

## Function - Delete all backups for with matching hostname and retention date
gcd-delete_all_snap ()
{
    exit_code=0
    (
        pids=""
        host_name=$1
        retention_date=$(date "+%Y%m%d")
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  Start deleting old backup for $host_name with retention date ${retention_date}"
        logMsg "INFO" "================================================================================="
        list_of_disks=$( gcloud compute disks list --format='value(name)' --filter="users~'${host_name}$'" )
        list_of_snaps=""
        list_of_snaps1=""
        for disk in $list_of_disks
        do
            list_of_snaps+=$( gcloud compute snapshots list --filter="name:($disk) AND labels.retention_date:'${retention_date}*'" --uri )" "
            list_of_snaps1+=$( gcloud compute snapshots list --filter="name:($disk) AND labels.retention_date:'${retention_date}*'")", "
        done
        list_of_snaps1=${list_of_snaps1::-2}
        logMsg "INFO" "List of snapshots to be deleted. If only comas (,) - no spanpshots to be deleted"
        logMsg "INFO" "$list_of_snaps1"
        for SNAP_NAME in ${list_of_snaps}
        do
        (
            gcd_run_gcloud_del $SNAP_NAME
            exit_code=$?
            exit $exit_code
        ) &
        pids+="$! "
        done
        local IFS=" "
        for p in $pids
        do
           if wait $p; then
              echo "Process $p success"
              exit_code=0
           else
              echo "Process $p fail"
              exit_code=$((exit_code+1))
           fi
        done
        logMsg "INFO" "gcd-backup_all_disk EXIT CODE $exit_code"
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  End creating backup for all disk for $1"
        logMsg "INFO" "================================================================================="
    exit $exit_code
    ) 2>&1 | tee -a $LOG_FILE
    exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]
    then
        exit_code=1
    fi
    return $exit_code
}

## Function - Backup ALL Disks
gcd-backup_all_disk ()
{
    exit_code=0
    (
    pids=""
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  Start creating backup for all disk for $1"
        logMsg "INFO" "================================================================================="
        host_zone=$( gcloud compute instances list --format='value(zone)' --filter="name~'${1}$'" )
        list_of_disks=$( gcloud compute disks list --format='value(name)' --filter="users~'${1}$'" )
        RETENTION_DAYS=$2
        for DISK_NAME in ${list_of_disks}
        do
        (
            gcd_run_gcloud_snap $DISK_NAME $host_zone ${RETENTION_DAYS}
            exit_code=$?
        exit $exit_code             
        ) &
        pids+="$! "
        done
        local IFS=" "
        for p in $pids
        do
           if wait $p; then
              echo "Process $p success"
              exit_code=0
           else
              echo "Process $p fail"
              exit_code=$((exit_code+1))
           fi
        done
        logMsg "INFO" "gcd-backup_all_disk EXIT CODE $exit_code"
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  End creating backup for all disk for $1"
        logMsg "INFO" "================================================================================="
    exit $exit_code
    ) 2>&1 | tee -a $LOG_FILE
    exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]
    then
        exit_code=1
    fi
    return $exit_code
}

## Function - Get list of disks
gcd-backup_list_disk ()
{
    exit_code=0
    (
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  Start creating backup of following disks"
        logMsg "INFO" "  $2"
        logMsg "INFO" "  for $1 host"
        logMsg "INFO" "================================================================================="
        ## Get the zone name for instance $1
        host_zone=$( gcloud compute instances list --format='value(zone)' --filter="name~'${1}$'" )

        ## Looping to disk names for creating a snapshot
        local IFS=","
        pids=""
        for DISK_NAME in $2
        do
        (
            RETENTION_DAYS=$( echo "${DISK_NAME}" | cut -d ":" -f 2 )
            if [ ${RETENTION_DAYS} == ${DISK_NAME} ]
            then
                logMsg INFO Using default retention days ${DAYS_RETENTION} for ${DISK_NAME}
                RETENTION_DAYS=${DAYS_RETENTION}
            else
                DISK_NAME=$( echo "${DISK_NAME}" | cut -d ":" -f 1 )
                logMsg INOF Retention days for ${DISK_NAME} is $RETENTION_DAYS
            fi
            gcd_run_gcloud_snap $DISK_NAME $host_zone $RETENTION_DAYS
            exit_code=$?
        exit $exit_code
        ) &
        pids+="$! "
        done
        logMsg "INFO" "gcd-backup_list_disk pds $pids"
        local IFS=" "
        for p in $pids
        do
           if wait $p; then
              echo "Process $p success"
          exit_code=0
           else
              echo "Process $p fail"
          exit_code=$((exit_code+1))
           fi
        done        
        logMsg "INFO" "gcd-backup_list_disk EXIT CODE $exit_code"
        logMsg "INFO" "================================================================================="
        logMsg "INFO" "  End creating backup for disks for $1"
        logMsg "INFO" "================================================================================="
        exit $exit_code
    ) 2>&1 | tee -a $LOG_FILE
    exit_code=${PIPESTATUS[0]}
    if [ $exit_code  -ne 0 ]
    then
    exit_code=1
    fi  
    return $exit_code
}

### Function to send email
##    $1) Subject
##    $2) File with body
function emailIt ()
{
    unix2dos ${2}
    BODY="$(cat ${2})"
    echo ${BODY} | ${EMAIL_CMD} -s "${1}" -c "${EMAIL_CC}" "${EMAIL_TO}"
}
