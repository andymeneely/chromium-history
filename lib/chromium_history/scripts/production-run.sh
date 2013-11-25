#!/bin/bash

export GEM_HOME=/home/axmvse/.gems
export GEM_PATH="/home/axmvse/.gems/:$GEM_PATH"
export PATH="$PATH:/home/axmvse/.gems/bin"
export RUBYOPT=rubygems

HISTORY_DIR=/home/axmvse/chromium/production-history
LOGS_DIR=/home/axmvse/logs
DATE=$(date +"%Y_%m_%d_%H_%M_%s")
ERR="/home/axmvse/logs/err_$DATE.log"
LOG="/home/axmvse/logs/log_$DATE.log"

export RAILS_ENV="production"

cd $HISTORY_DIR
git clean -f
git pull
bundle
rake run 1>$LOG 2>$ERR

#Email the status report
rm /tmp/email.txt
echo -e "\n\n\n\n\n----------------git log --since="1 day ago" --stat------------------------\n\n\n\n\n" >> /tmp/email.txt
git log --since="1 day ago" --stat >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stdout------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $LOG >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stderr------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $ERR >> /tmp/email.txt
cat /tmp/email.txt | /usr/bin/mail "andy.meneely@gmail.com" -s "Chromium History Build server status report"
