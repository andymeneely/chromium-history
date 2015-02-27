#!/bin/bash

export GEM_HOME="$HOME/.gems"
export GEM_PATH="$HOME/.gems/:$GEM_PATH"
export PATH="$HOME/.gems/bin:$PATH"
export RUBYOPT=rubygems

HISTORY_DIR="$HOME/chromium/build-repo"
LOGS_DIR="$HOME/logs"
DATE=$(date +"%Y_%m_%d_%H_%M_%s")
ERR="$HOME/logs/err_$DATE.log"
LOG="$HOME/log_$DATE.log"
OUTCOME="FAILED"

export RAILS_ENV="production"
export RAILS_BLAST_PRODUCTION="YesPlease"

mkdir -p /run/shm/chromium/realdata
mkdir -p /run/shm/tmp/production
rsync -a ~/chromium/realdata /run/shm/chromium/

cd $HISTORY_DIR
git clean -f
git pull
bundle
rm /tmp/prod-email.txt
echo -e "\n\n\n\n\n----------------git log -5 --stat------------------------\n\n\n\n\n" >> /tmp/prod-email.txt
git log -5 --stat >> /tmp/prod-email.txt

rake run 1>$LOG 2>$ERR

if [[ -s $ERR ]]; then
    echo "Errors in the error log - not changing to chromium_real" 1>>$LOG
else
    VERIFY_PASS=`grep "^Verify completed.*0 failed" $LOG`
    if [[ -n $VERIFY_PASS ]]; then
    	OUTCOME="SUCCESS!"
    else
	OUTCOME="Verifies failed"
    fi ;
    rake run:stats run:results 1>>$LOG 2>>$LOG #Still change to real if errors in error log
    psql -U archeology chromium_test -c" SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'chromium_real2' AND procpid <> pg_backend_pid()"
    psql -U archeology chromium_test -c" SELECT pg_terminate_backend(pg_stat_activity.procpid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'chromium_real' AND procpid <> pg_backend_pid()"
    psql -U archeology chromium_test -c "DROP DATABASE chromium_real" 1>>$LOG 2>>$ERR
    psql -U archeology chromium_test -c "ALTER DATABASE chromium_real2 RENAME TO chromium_real" 1>>$LOG 2>>$ERR
fi ; 

#Email the status report
echo -e "\n\n\n\n\n----------------stderr------------------------\n\n\n\n\n" >> /tmp/prod-email.txt
cat $ERR >> /tmp/prod-email.txt
echo -e "\n\n\n\n\n----------------stdout------------------------\n\n\n\n\n" >> /tmp/prod-email.txt
cat $LOG >> /tmp/prod-email.txt
cat /tmp/prod-email.txt | /usr/bin/mail "chromium-history@se.rit.edu, andy.meneely@gmail.com" -s "[Chromium History] Production Build: $OUTCOME"

#Post to Slack
curl -X POST --data-urlencode "payload={\"channel\": \"#build\", \"username\": \"webhookbot\", \"text\": \"Production build: $OUTCOME. See email for details.\", \"icon_emoji\": \":ghost:\" } " https://softarcheology.slack.com/services/hooks/incoming-webhook?token=8dbu9krt70iSbjMUgI6WAJvJ
