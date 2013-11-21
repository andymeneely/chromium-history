#!/bin/bash

HISTORY_DIR=/home/axmvse/chromium/production-history
LOGS_DIR=/home/axmvse/logs
DATE=$(date +"%Y_%m_%d_%H_%M_%s")
ERR="err_$DATE.log"
LOG="log_$DATE.log"

export RAILS_ENV="production"

cd $HISTORY_DIR
git pull
rake run 1>$LOG 2>$ERR

#Email the status report
rm /tmp/email.txt
echo "\n\n\n\n\n----------------git log -1------------------------\n\n\n\n\n" >> /tmp/email.txt
git log -1 1>>/tmp/email.txt
echo "\n\n\n\n\n----------------stdout------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $LOG >> /tmp/email.txt
echo "\n\n\n\n\n----------------stderr------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $ERR >> /tmp/email.txt
cat /tmp/email.txt | /usr/bin/mail "andy.meneely@gmail.com" -s "Chromium History Build server status report"
