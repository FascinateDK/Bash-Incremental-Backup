#!/bin/bash

# Configuration variables
source="${2##*:}"
destination="${4##*:}"
logDir="${destination}/logs"
logFile="${destination}/logs/backup_$(basename "$source").log"
dataFile="${destination}/data/$(basename $source)"
remote=

if [ -z ${5} ] || [ ${5} != "--retention" ]
then
  retention=7
else
  retention=${6}
fi

# Functions
pushLog()
{
  echo -e "${1}" | tee -a "$logFile"
}

pushHelper()
{
  echo "Usage : ./bash-incremental-backup --source <path_to_source> --destination <path_to_destination> --retention <numer_of_retention_day>"
  echo "\n"
  echo "--source : source path to backup"
  echo "--destination : destination path to save backup files"
  echo "--retention : number of days to keep bakcups"
}

if [ ${1} != "--source" ] || [ ${3} != "--destination" ] || [ ! -d ${2} ]
  then
  echo "Something went wrong..."
  pushHelper

else
  # Initialization
  mkdir -p ${dataFile}
  mkdir -p ${logDir}
  touch $logFile

  # Removing older backup's folder if retention changed
  if [ $retention -lt 9 ]
  then
    del=$(($retention+1))
    rm -rf ${dataFile}/backup.1[0-9]
    rm -rf ${dataFile}/backup.[${del}-9]
  else
    rm -rf ${dataFile}/backup.1[0-9]
  fi

  # Backup folder creation according to retention
  for (( i=0; i<=${retention}; i++ ))
  do
     mkdir -p ${dataFile}/backup.${i}
  done

  # Pushing log into log's file
  pushLog "Starting rsync service at : $(date -Id) $(date +%H:%M:%S) \n"
  pushLog "Configuration :"
  pushLog "Source : ${source}"
  pushLog "Destination : ${destination}"
  pushLog "Remote mode : ${remote}"

  # Removing last day folder according to retention
  /bin/rm -rf $dataFile/backup.${retention}

  for (( i=1; i<=$((retention-1)); i++ ))
  do

  	 count=$((retention-$i+1))
  	 toMove=$((retention-$i))

     mv $dataFile/backup.${toMove} $dataFile/backup.${count}
  done

  # Incremental backup execution
  /usr/bin/rsync -e ssh -achv --no-o --delete --safe-links --log-file=${logFile} --link-dest=$dataFile/backup.2 $source $dataFile/backup.1/

  # Check success
  if [ "${?}" -eq "0" ]
  then
  	pushLog "\n[$(date -Is)] Backup completed successfully : $(date -Id) $(date +%H:%M:%S)\n"
  else
  	pushLog "\n[$(date -Is)] Backup failed, try again later : $(date -Id) $(date +%H:%M:%S)\n"
  fi
    savelog -q -m 640 -c ${retention} -l ${logFile}
fi
