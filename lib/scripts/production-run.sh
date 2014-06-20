#!/bin/bash

export GEM_HOME=/home/axmvse/.gems
export GEM_PATH="/home/axmvse/.gems/:$GEM_PATH"
export PATH="$PATH:/home/axmvse/.gems/bin"
export RUBYOPT=rubygems


HISTORY_DIR=/home/axmvse/chromium/build-repo
LOGS_DIR=/home/axmvse/logs
DATE=$(date +"%Y_%m_%d_%H_%M_%s")
ERR="/home/axmvse/logs/err_$DATE.log"
LOG="/home/axmvse/logs/log_$DATE.log"

export RAILS_ENV="production"
export RAILS_BLAST_PRODUCTION="YesPlease"


cd $HISTORY_DIR
git clean -f
git pull
bundle
rake run 1>$LOG 2>$ERR

if [[ -s $ERR ]]; then
    echo "Errors in the error log - not changing to chromium_real" 1>>$LOG
else
    rake run:stats run:results 1>>$LOG 2>>$LOG #Still change to real if errors in error log
    psql -U archeology chromium_test -c" SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'chromium_real2' AND procpid <> pg_backend_pid()"
    psql -U archeology chromium_test -c" SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'chromium_real' AND procpid <> pg_backend_pid()"
    psql -U archeology chromium_test -c "DROP DATABASE chromium_real" 1>>$LOG 2>>$ERR
    psql -U archeology chromium_test -c "ALTER DATABASE chromium_real2 RENAME TO chromium_real" 1>>$LOG 2>>$ERR
fi ; 

#Email the status report
rm /tmp/email.txt
echo -e "\n\n\n\n\n----------------git log -5 --stat------------------------\n\n\n\n\n" >> /tmp/email.txt
git log -5 --stat >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stdout------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $LOG >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stderr------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $ERR >> /tmp/email.txt
cat /tmp/email.txt | /usr/bin/mail "andy.meneely@gmail.com" -s "Chromium History Build server status report"
