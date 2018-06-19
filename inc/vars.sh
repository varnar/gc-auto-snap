#!/bin/bash
###----------------------------------------------------------------------------
### Script Name:    vars.sh
### Description:    Variables for main script
###----------------------------------------------------------------------------

## Global Variables
SCRIPT_NAME=$(basename "$0" .sh)
SYS_NAME=$(hostname|cut -d. -f1)
CUR_DATETIME=$(date "+%Y%m%d-%H%M%S")

## Path Variables
CONFIG_FILE=${SCRIPT_DIR}/config/${1}

## Log file Variables
LOG_DIR=${SCRIPT_DIR}/logs
LOG_FILE=${LOG_DIR}/disk-backup-${CUR_DATETIME}.log

## Snapshot Variables
if [ "$2" == "" ]
then
    SNAP_PREFIX_PRE="bkp-"
    SNAP_PREFIX="bkp-$(date +%Y%m%d)"
else
    SNAP_PREFIX_PRE="bkp-${2}"
    SNAP_PREFIX="bkp-${2}-$(date +%Y%m%d)"
fi

## Default value to retention
DAYS_RETENTION=3

## Check if CONFIG_FILE was passed
if [ "$CONFIG_FILE" == "" ]
then
    echo "Please provide config file. Exiting."
    exit 1
fi

if [ ! -f $CONFIG_FILE ]
then
    echo "Config file does not exist. Exiting"
    exit 1
fi

## Email Variables
EMAIL_CMD=$(which mutt)
EMAIL_FROM="${SCRIPT_NAME}-${SYS_NAME} <${SCRIPT_NAME}-${SYS_NAME}@email.com>"
export EMAIL="${EMAIL_FROM}"
EMAIL_TO="email@email.com"
EMAIL_CC="email@email.com"
EMAIL_BODY=${LOG_FILE}

