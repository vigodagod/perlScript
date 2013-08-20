#!/bin/sh
#  FILE: backup-config.sh
#  AUTHOR: vigodagod [vigodagod@gmail.com]
#  VERSION: 1.1
#  DATE:    03/23/2011

# ACCOUNT_ROOT can be found on the Features tab in the control panel for the site
ACCOUNT_ROOT="/home/myWebSite"    # FULL PATH TO ACCOUNT, no ending slash

WEB_SITE="www.myWebSite.com"   # live site domain

FTPNUM=2                                    # number of backup's before file will be ftp'd

# MYSQL DB VARIABLES
# DB_NAME ARRAY
#   USAGE: Add as many databases you want by incrementing the array index
#          Add incremented variables for HOST, USER, and PASS to 
#          correspond with the array key

DB_NAME[0]="myWebSite_wp1"                        # DB #1
DB_HOST_0="90.0.0.1"                              # DB #1 HOST
DB_USER_0="myWebSite_wpuser"                      # DB #1 USER
DB_PASS_0="wppassword"                            # DB #1 PASS

DB_NAME[1]="myOtherSite_wp1"                      # DB #2
DB_HOST_1="90.0.0.1"                              # DB #2 HOST
DB_USER_1="myOtherSite_wpuser"                    # DB #2 USER
DB_PASS_1="wppassword"                            # DB #2 PASS

# OMIT FILES/DIRECTORIES
#   USAGE: List files/directories that you 
#          do not wish to include  in the back-up
#          within the $SITE_ROOT
OMIT_DIR=""
#OMIT_DIR[0]="videos"
#OMIT_DIR[1]="files/private"

# FTP VARIABLES
FTP_HOST='120.0.255.1';    # ftp host
FTP_USER='ftp_username';   # ftp user
FTP_PASS='ftp_password';   # ftp password
FTP_DIR='/httpdocs/backup' # back up directory where files will be FTP'd


#================  DO NOT EDIT BELOW THIS LINE  ==========
SITE_ROOT="$ACCOUNT_ROOT/public_html"       # where web files are located on server
BACK_ROOT="$ACCOUNT_ROOT/backup"            # where backup files are located on server
DATE=`date +%Y-%m-%d-%H-%M-%S`              # date command, echoes YYYY-MM-DD-HH-II-SS
BU_COUNT_DIR="$BACK_ROOT/cnt"               # **DON'T EDIT** directory and count file
BU_COUNT_NUM=0                              # count number, must be zero
ftpFiles=FALSE                              # **DON'T EDIT** Toggle, determines when to FTP back-up files;
BACKUP_SQL_FILE=$WEB_SITE'-sql-'$DATE'.tgz' # **DON'T EDIT**
BACKUP_WEB_FILE=$WEB_SITE'-web-'$DATE'.tgz' # **DON'T EDIT**
DB_COUNT=0

echo "=====  START SCRIPT ================================"
echo "=====  ECHO FULL PATH WHERE SCRIPT IS RUNNING  ====="
pwd
echo " "
echo "=====  VERIFY THAT COUNT FILE EXISTS  =============="
# VERIFY THAT BU_COUNT_DIR FILE EXISTS
if test ! -e "$BU_COUNT_DIR"
then
    echo "=====  COUNT FILE DIRECTORY DOES NOT EXIST  ========"
    # $BU_COUNT_DIR DOES NOT EXIST
    echo "=====  CREATE DIRECTORY AND SET COUNT FILE  ========"
    
    # CREATING AND SETTING $BU_COUNT_DIR
    expr '1' > $BU_COUNT_DIR
else 
    echo "=====  COUNT FILE DIRECTORY EXISTS  ================"
    echo "=====  READ IN COUNT NUMBER  ======================="
    read BU_COUNT_NUM < $BU_COUNT_DIR
    echo "COUNT: $BU_COUNT_NUM"

    echo "=====  INCREMENT COUNT FILE  ======================="
    # FTP FILE EVERY 5TH BACKUP
    if test "$BU_COUNT_NUM" -gt $FTPNUM
    then
	BU_COUNT_NUM=0
	ftpFiles=TRUE
    fi
    expr $((BU_COUNT_NUM+1)) > $BU_COUNT_DIR
fi

echo "=====  READ IN NEW COUNT NUMBER====================="
read BU_COUNT_NUM < $BU_COUNT_DIR # GET BACK UP SUB DIRECTORY NAME

echo "NEW COUNT: $BU_COUNT_NUM"

echo "=====  MOVE INTO BACK UP DIRECTORY  ================"
cd $BACK_ROOT
pwd

# CHECK IF COUNT NUM DIRECTORY EXISTS
# IF SO, REMOVE CONTENTS
# OTHERWISE CREATE IT
if test ! -e "$BACK_ROOT/$BU_COUNT_NUM"
then
    
    echo "=====  COUNT NUM DIRECTORY DOES NOT EXIST  ========="
    echo "=====  CREATE $BACK_ROOT/$BU_COUNT_NUM  ============"
    mkdir $BU_COUNT_NUM
else 
    echo "=====  COUNT NUM DIR EXISTS... REMOVING CONTENTS  =="
    rm -rf $BACK_ROOT/$BU_COUNT_NUM/*
fi

echo "=====  MAKE TEMP DIRECTORY  ========================"
mkdir "tmp"

echo "===== MOVE INTO BACK UP DIRECTORY  ================="
cd $BACK_ROOT
pwd

for db in ${DB_NAME[@]}
do
    echo $db
    
    # need to move stuff from copy-backup-mysql.sh to this area
    
    eval DB_HOST=\$DB_HOST_$DB_COUNT
    eval DB_USER=\$DB_USER_$DB_COUNT
    eval DB_PASS=\$DB_PASS_$DB_COUNT
    
    #    ./backup-mysql.sh $BACK_ROOT $DB_HOST $DB_USER $DB_PASS $db
    /bin/sh $BACK_ROOT/backup-mysql.sh $BACK_ROOT $DB_HOST $DB_USER $DB_PASS $db
    DB_COUNT=$((DB_COUNT+1))
done


echo "=====  CHECK TO SEE IF ANY DB FILES WERE DUMPED  ==="
if [ "$(ls -A $BACK_ROOT/tmp/ 2> /dev/null)" == "" ];
then
    echo "=====  NO SQL FILES WERE BACKED UP  ================"
else
    echo "====  MOVE INTO tmp DIRECTORY  =====================";
    cd  $BACK_ROOT/tmp

    echo "=====  TAR UP DATABASE FILES ======================="
    pwd
    response=`tar czf $BACKUP_SQL_FILE *.sql`
    if test "$response" == ""
    then
	echo "=====  SQL TAR SUCCESS  ============================"
    else
	echo "=====  SQL TAR FAILED  ============================="
    fi
    
    # REMOVE STRAY SQL FILES
    echo "=====  REMOVE STRAY SQL FILES FROM tmp/=============="
    rm -rf *.sql
    
    # MOVE SQL TAR TO BACKUP COUNT DIR
    echo "=====  MOVE SQL TAR TO BACKUP COUNT DIR  ============"
    echo "$BACKUP_SQL_FILE $BACK_ROOT / $BU_COUNT_NUM /.";
    mv $BACKUP_SQL_FILE $BACK_ROOT/$BU_COUNT_NUM/.
fi


# START WEB FILE BACKUP AREA
echo "=====  START WEB FILE BACKUP  ======================"
echo "=====  MOVE INTO tmp directory [BACK_ROOT/tmp/web]  "
cd $BACK_ROOT/tmp
# CREATE BACKUP WEB DIR [BACK_ROOT/tmp/web]
echo "=====  CREATE BACKUP WEB DIR [BACK_ROOT/tmp/web]  =="
mkdir "web"

# MOVE INTO 'web' DIRECTORY
cd web
pwd

# COPY WEB DIRECTORY CONTENTS OVER TO 'web'
response=`cp -rf $SITE_ROOT/* .`
if test "$response" == ""
then
    echo "response: $response"
    echo "=====  SITE COPY SUCCESS  =========================="
else
    echo $response
    echo "=====  SITE COPY FAIL  ============================="
    echo "=====  ABORT SCRIPT  ==============================="
    exit
fi

for dir in ${OMIT_DIR[@]}
do
    echo "remove $dir"
    rm -rf $dir
done 

# MOVE BACK A DIRECTORY
cd ../
pwd

# TAR UP WEB DIRECTORY
response=`tar czf $BACKUP_WEB_FILE web/*`

if test "$response" == ""
then
    echo "====  WEB TAR SUCCESS  ============================="
else
    echo "====  WEB TAR FAILED  =============================="
    echo "====  ABORT SCRIPT  ================================"
    exit
fi

# REMOVE tmp/web DIRECTORY
echo "====  REMOVE WEB COPY  ============================="
rm -rf web

echo "====  MOVE SQL TAR TO BACKUP COUNT DIR  ============"
echo "mv $BACKUP_WEB_FILE $BACK_ROOT/$BU_COUNT_NUM/. ====="
mv $BACKUP_WEB_FILE $BACK_ROOT/$BU_COUNT_NUM/.

# MOVE BACK A DIRECTORY
cd ../

# REMOVE TEMP DIRECTORY
rmdir tmp

# FUNTION: ftpPut
# LOCATION: needs to be above where it is used to be executed
# USAGE:   ftpPut {local dir} {ftp dir} {file}
#   - local dir = where the file currently resides
#   - ftp dir   = where the file will go on the server
#   - file      = file to upload
function ftpPut {
    ftp -n $FTP_HOST <<EOF
    quote USER $FTP_USER
    quote PASS $FTP_PASS
    binary
    lcd $1 
    cd $2 
    put $3
    quit
EOF
}

if test "$ftpFiles" == TRUE
then
    echo "FTP FILES"
    
    if test ! -e "$BACK_ROOT/$BU_COUNT_NUM/$BACKUP_SQL_FILE"
    then
	
	echo "====  NO DATABASES TO FTP  ========================="
    else
	echo "$BACK_ROOT/$BU_COUNT_NUM $FTP_DIR $BACKUP_SQL_FILE  "
	ftpPut $BACK_ROOT/$BU_COUNT_NUM $FTP_DIR $BACKUP_SQL_FILE
    fi
    
    ftpPut $BACK_ROOT/$BU_COUNT_NUM $FTP_DIR $BACKUP_WEB_FILE
    
    # this code listed oldest file in a directory [not needed]
    # echo "ls -1tr $BACK_ROOT/ | grep web | tail -1"
    # response=`ls -1t $BACK_ROOT/ | grep web | tail -1`
    # echo $response
    # response=`ls -1t $BACK_ROOT/ | grep sql | tail -1`
    # echo $response
fi

echo "====  END SCRIPT  =================================="
