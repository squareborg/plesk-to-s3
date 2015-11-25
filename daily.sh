#/bin/bash
# _                               
#| |_ _ _ ___ ___ ___ ___ ___ _ _ 
#|   | | | . | -_|  _|_ -|  _| | |
#|_|_|_  |  _|___|_| |___|_|  \_/ 
#    |___|_|                      
#
# hypersrv.com | Web at scale solutions
#
# daily.sh Stephen Martin <sm@hypersrv.com>
# ------------------------------------------
# Script to backup plesk backups to amazon s3
# 
# Copyright (c) 2015, Stephen Martin <sm@hypersrv.com>
# All rights reserved. 

# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met: 

#  * Redistributions of source code must retain the above copyright notice, 
#    this list of conditions and the following disclaimer. 
#  * Redistributions in binary form must reproduce the above copyright 
#    notice, this list of conditions and the following disclaimer in the 
#    documentation and/or other materials provided with the distribution. 

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY 
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY 
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH 
# DAMAGE. 




# setup in cron as 
# 0 1 * * * /root/hypersrv.com/plesk-to-s3/daily.sh > /dev/null 2>&1

# Config
EMAIL="" # Email address to report to eg, "sm@hypersrv.com,email@hypersrv.com
PREFIX="backup" # Prefix of backups in plesk manager. eg. main this is always "backup" in plesk 12.5
KEEP=14 # The amount of backups to Keep on S3
AWS_ACCESS_KEY_ID="" #  The AWS access key ID
AWS_ACCESS_KEY_SECRET="" # The AWS access key secret
BUCKETNAME="" # the AWS S3 bucket name eg. mybucket
ARCHIVENAME="daily" # the archive name for the bucket eg. "daily" to store backups in mybucket/daily
LOGFILE=/root/hypersrv.com/plesk-to-s3/$ARCHIVENAME.log # The log file location
# /Config


/root/hypersrv.com/plesk-to-s3/plesk-to-s3.sh -p $PREFIX -K $KEEP -i $AWS_ACCESS_KEY_ID -k $AWS_ACCESS_KEY_SECRET -b $BUCKETNAME -a $ARCHIVENAME > $LOGFILE 2>&1
RET=$?
if [ ! $RET -eq 0 ];then
	echo "The backup job $ARCHIVENAME failed" | mail -s "$ARCHIVENAME Backup to s3 failed see attached log" -a $LOGFILE "$EMAIL"
else
	echo "The backup job $ARCHIVENAME was succesful" | mail -s "$ARCHIVENAME Backup to s3 was successful" -a $LOGFILE "$EMAIL"
fi

