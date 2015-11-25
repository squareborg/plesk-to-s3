#!/bin/bash
# _                               
#| |_ _ _ ___ ___ ___ ___ ___ _ _ 
#|   | | | . | -_|  _|_ -|  _| | |
#|_|_|_  |  _|___|_| |___|_|  \_/ 
#    |___|_|                      
#
# hypersrv.com | Web at scale solutions
#
# plesk-to-s3.sh Stephen Martin <sm@hypersrv.com>
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

usage (){
cat << EOF
usage: $0 options
-p Prefix of backups in plesk manager.
-K The amount of backups to Keep on S3
-i The AWS access key ID
-k The AWS access key secret
-b the AWS S3 bucket name eg. mybucket
-a the archive name for the bucket eg. "daily" to store backups in mybucket/daily
EOF
}

while getopts "p:K:i:k:b:a:" OPTION
do
	case $OPTION in
		p)
			PREFIX=$OPTARG
			;;
		K)
			KEEP=$OPTARG
			;;
		i)
			export AWS_ACCESS_KEY_ID=$OPTARG
			;;
		k)
			export AWS_SECRET_ACCESS_KEY=$OPTARG
			;;
		b)
			BUCKETNAME=$OPTARG
			;;
		a)
			ARCHIVENAME=$OPTARG
			;;
	esac
done

which s3cmd > /dev/null 2>&1
RET=$?
if [ ! $RET -eq 0 ];then
	echo "[!] FATAL error no s3cmd, please install from http://s3tools.org/s3cmd"
	exit 1
fi

if [[ -z $PREFIX ]] ||  [[ -z $KEEP ]] || [[ -z $AWS_ACCESS_KEY_ID ]] || [[ -z $AWS_SECRET_ACCESS_KEY ]] || [[ -z $BUCKETNAME ]];then
	usage
	exit 1
fi
			
echo "============================================="
echo "[+] Starting backup $(date)"
TMPSTAGE=/root/hypersrv.com/plesk-to-s3/tmp
#clean up old tmp
echo "[+] Cleaning up old tmp files"
rm -rf $TMPSTAGE
# Get the latest backup with prefix
BKTIMESTAMP=$(basename $(ls -t /var/lib/psa/dumps/"$PREFIX"_*.xml | head -n 1) | perl -pe 's/^.*_([0-9]{10})\.xml$/$1/')
echo "[+] Latest time stamp: $BKTIMESTAMP"
BKFILES=$(find /var/lib/psa/ -type f -name "$PREFIX"_*$BKTIMESTAMP*)
BKDIRS=$(find /var/lib/psa/ -name "$PREFIX"_*$BKTIMESTAMP* -exec dirname {} \; | sort | uniq)
for d in $BKDIRS
do
        if [ ! -d "$TMPSTAGE"$d ]; then
        echo "[+] Creating tmp dir: "$TMPSTAGE"$d"
        mkdir -p  "$TMPSTAGE"$d
        fi
done
for f in $BKFILES
do
        ln -s $f $TMPSTAGE/$f
done
echo "[+] Syncing to S3 $(date)"
s3cmd sync -F $TMPSTAGE/var/lib/psa/ s3://"$BUCKETNAME"/backup/$ARCHIVENAME/$BKTIMESTAMP/
echo "[+] Finished syncing to S3 $(date)"
RET=$?
if [ ! $RET -eq 0 ];then
	echo "[!] Error accessing S3.. exiting. $(date)"
	exit 1
fi
#find /var/lib/psa/ -name main_*$BKTIMESTAMP* -exec dirname {} \; | sort | uniq
ARCHIVELS=$(s3cmd ls -l s3://$BUCKETNAME/backup/$ARCHIVENAME/)
RET=$?
if [ ! $RET -eq 0 ];then
	echo "[!] Error accessing S3.. exiting. $(date)"
	exit 1
else
	ARCHIVECOUNT=$(echo "$ARCHIVELS" | wc -l)
	if [ $ARCHIVECOUNT -gt $KEEP ];then
		echo "[+] Over archive retention policy - Policy: $KEEP Archive Count: $ARCHIVECOUNT"
		echo "[+] We are over the archive limit deleting some dailys..."
		DELETEARCHIVES="$(echo "$ARCHIVELS" | head -n $(( $ARCHIVECOUNT - $KEEP)) | cut -f 2 -d ':' )"
		for ARCHIVE in $DELETEARCHIVES
		do
			echo "Delete $ARCHIVE"
			s3cmd rm --recursive s3:$ARCHIVE
			SUBRET=$?
			if [ ! $SUBRET -eq 0 ];then
				echo "[!] Error deleting from S3.. exiting.i $(date)"
				exit 1
			fi
		done
	else
		echo "[+] Under archive retention policy - Policy: $KEEP Archive Count: $ARCHIVECOUNT"
	fi
fi
echo "[+] Backup complete $(date)"
exit 0

