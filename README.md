# Discontinued, un-maintained Plesk now has its own S3 sync

### Tested on
* Plesk 12
* Plesk 12.5
* Plesk Onyx 17.5.3 Update #38

Intro
-----
This is a simple script.  It has been designed to use cron jobs to schedule backups of your plesk server backups to Amazon S3. It will also allow for multiple retention policy eg. 14 daily's and 12 monthly's.

**WARNING** This only works for Plesks's *full* backups, it will not work for incremental backups. Always test your backups.

When your crontab runs it will copy the latest backup it can find on your plesk server and upload it to an S3 bucket of your choosing. This script does not schedule the actual backups of Plesk but merely copies the backups that the built in Plesk backup manager runs and puts them on S3


Install
-------

Requirements

- [s3cmd](http://s3tools.org/s3cmd)
- python setuptools
- wget

# CENTOS / RHEL

Please run the following commands as the `root` user

	yum install python-setuptools wget
	wget https://github.com/s3tools/s3cmd/archive/master.zip
	unzip master.zip
	cd s3cmd-master/
	python setup.py install
	cd ..
	rm -rf master.zip s3cmd-master/
	wget https://github.com/stedotmartin/plesk-to-s3/archive/master.zip
	unzip master.zip
	cd plesk-to-s3-master
	mkdir -p /opt/hypersrv.com/plesk-to-s3/
	cp {plesk-to-s3,daily,monthly}.sh /opt/hypersrv.com/plesk-to-s3/
	chmod 700 /opt/hypersrv.com/plesk-to-s3/{plesk-to-s3,daily,monthly}.sh
	cd ..
	rm -rf master.zip plesk-to-s3-master


# Jobs

We use `cron` to schedule what times we want to copy our local plesk backups to s3

After you have installed we supply two sample jobs to copy data to s3 `/opt/hypersrv.com/plesk-to-s3/daily.sh` and `/opt/hypersrv.com/plesk-to-s3/monthly.sh` 

Our **daily** job will copy the backup to s3 daily and keep 14 day of backups before removing the oldest backup to make way for newer ones.

**As we are doing daily backups to s3 your plesk backup schedule should also be running daily, make sure that you have setup this in the backup manager inside Plesk**

Our **monthly** job will copy the backup to s3 monthly and keep 12 months of backups before removing the oldest backup to make way for newer ones.

You will need to edit both of these jobs and enter in the required details, locate the config section, fill in the blanks or edit where you see fit.

`vi /opt/hypersrv.com/plesk-to-s3/daily.sh`


	# Config
	EMAIL="" # Email address to report to eg, "sm@hypersrv.com,email@hypersrv.com
	PREFIX="backup" # Prefix of backups in plesk manager in plesk 12 you could choose a backup name but now in 12.5 the prefix will always be "backup".
	KEEP=14 # The amount of backups to Keep on S3 for this job
	AWS_ACCESS_KEY_ID="" #  The AWS access key ID
	AWS_ACCESS_KEY_SECRET="" # The AWS access key secret
	BUCKETNAME="" # the AWS S3 bucket name eg. mybucket
	ARCHIVENAME="daily" # the archive name for the bucket eg. "daily" to store backups in mybucket/daily
	LOGFILE=/opt/hypersrv.com/plesk-to-s3/$ARCHIVENAME.log # The log file location
	# /Config

Do the same for the `/opt/hypersrv.com/plesk-to-s3/monthly.sh` job

Add the jobs to **root** cron

	crontab -u root -e

Add the below to the crontab file, change the times to **after** your Plesk backup has finished 
	
	# every day at 1am
	0 1 * * * /opt/hypersrv.com/plesk-to-s3/daily.sh > /dev/null 2>&1
	# first of every month at 2 am
	0 2 1 * * /opt/hypersrv.com/plesk-to-s3/monthly.sh > /dev/null 2>&1
	
# How to restore from an S3 backup


## To restore the whole server:

Download the entire "dumps" folder from S3 with the correct date eg. /mybucket/backup/daily/1511241645/dumps ( for 11 November 2015 @ 16:45)
Copy to your plesk server to the /var/lib/psa/dumps/ folder, choose overwrite if prompted. 

You can do this using `s3cmd` like this 

`s3cmd -v sync s3://plesktos3/backup/daily/1801271748/dumps/ /var/lib/psa/dumps/`

You should then access the plesk backup manager and see the entire backup available.



## To restore one subscription:

Download the entire first level of the backup you want to restore eg.  `/mybucket/backup/daily/1511241645/dumps/*` excluding the *domains* folder, 

copy your downloaded items to `/var/lib/psa/dumps/`
but then create an empty domains folder `/var/lib/psa/dumps/domains`

Now download the specific subscription folder from the domains folder inside the backup with the date you want to restore from eg. `/mybucket/backup/daily/1511241645/dumps/domains/test.com` and copy that into `/var/lib/psa/dumps/domains/`

You can now use the Plesk server backup manager to restore the backup




