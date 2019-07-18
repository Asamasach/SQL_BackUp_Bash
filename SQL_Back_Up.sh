#!/bin/bash

# author: Mahmoud Shiri Varamini(shirivaramini@gmail.com)
# birthdate: 28 May 2018,08:05
# modifier: -
# modified date: -
# version: 0.1
# description: this script written in order to backup mysql databases.


# exit status help
# 0 successfull
# 1 incorrect mysql backup user password
# 2 backup directory creation fail
# 3 .my.cnf file dose not exist


#create backup directory
SERVER="localhost"
BACKUP_MINOR_DIR=$(date +%Y%m%d)
BACKUP_DB_DIR="/backup/"
BACKUP_DB_NAME_PREFIX=$(date +%Y%m%d-%H%M%S)

if [ ! -d $BACKUP_DB_DIR ]; then
	mkdir -p $BACKUP_DB_DIR
	if [ $? -ne 0 ];then 
	logger "backup-db: couldn't create backup direcroty.backup operation faild"
	exit 2
	fi 
fi

mkdir $BACKUP_DB_DIR/$BACKUP_MINOR_DIR &> /dev/null

#mysql backup user and password 
MYSQL_USER="root"
MYSQL_PASSWORD=""


#read mysql password from stdin if empty
if [ -z "${MYSQL_PASSWORD}" ]; then
	echo -n "Enter MySQL ${MYSQL_USER} password: "
	read -s MYSQL_PASSWORD
	echo
fi



#check MySQL password
echo exit | mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -B 2>/dev/null
if [ $? -ne 0 ]; then
	logger  "backup-db: MySQL ${MYSQL_USER} password incorrect"
  	exit 1
fi

#get databases
MYSQL_DATABASES=$(echo 'show databases' | mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} -B | sed /^Database$/d)


# backup and compress each database
for database in $MYSQL_DATABASES
do
  	if [ "${database}" == "information_schema" ] || [ "${database}" == "performance_schema" ]; then
        	ADDITIONAL_MYSQLDUMP_PARAMS="--lock-tables=false "
  		else
       		ADDITIONAL_MYSQLDUMP_PARAMS="--lock-tables=false"
  	fi
	mysqldump ${ADDITIONAL_MYSQLDUMP_PARAMS}  --triggers  --routines --single-transaction --user=${MYSQL_USER} --password=${MYSQL_PASSWORD}  ${database}  | gzip --best > "${BACKUP_DB_DIR}/${BACKUP_MINOR_DIR}/${BACKUP_DB_NAME_PREFIX}-${database}.gz" 2> /dev/null
	if [ $? -eq 0 ];then
	logger "${database} backup sucess." 
	else
	logger  "${database} backup faild."
	fi
done
logger "mysql database backup done successfully.for more details check log file"
exit 0
