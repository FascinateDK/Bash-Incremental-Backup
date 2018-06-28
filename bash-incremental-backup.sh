#!/bin/bash

# Configuration variables
source="${2:-/path/to/source}"
destination="${4:-/path/to/target}"
retention=${6}

logDir="${destination}/logs"
logFile="${destination}/logs/backup_$(basename "$source")_$(date -Id)_$(date +%H-%M-%S).log"
dataFile="${destination}/data/$(basename $source)"

remote=False
timeout=1800

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

if [ ${1} != "--source" ] || [ ${3} != "--destination" ] || [ ${5} != "--retention" ] || [ ! -d ${2} ]
  then
  echo "Something went wrong..."
  pushHelper

else
  # Initialization
  mkdir -p ${dataFile}
  mkdir -p ${logDir}
  touch $logFile

  # Removing older backup's folder if retention changed
  #if [ ${dataFile}/backup.$retention+1 ]
  echo ${dataFile}/backup.$retention+1

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
  #/usr/bin/rsync -achv --no-o --delete --safe-links --log-file=${logFile} --link-dest=$dataFile/backup.2 $source $dataFile/backup.1/

  # Check success
  if [ "${?}" -eq "0" ]
  then
  	pushLog "\n[$(date -Is)] Backup completed successfully\n"
  else
  	pushLog "\n[$(date -Is)] Backup failed, try again later\n"
  fi
fi
