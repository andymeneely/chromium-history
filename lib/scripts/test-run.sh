#!/bin/bash

export GEM_HOME=/home/axmvse/.gems
export GEM_PATH="/home/axmvse/.gems/:$GEM_PATH"
export PATH="$PATH:/home/axmvse/.gems/bin"
export RUBYOPT=rubygems


HISTORY_DIR=/home/axmvse/chromium/build-repo

cd $HISTORY_DIR
git clean -f
STATUS=$(git pull)

echo $STATUS

if [ "Already up-to-date." == "$STATUS" ]
then
    exit 0
fi

#Otherwise, let's do the run!
export RAILS_ENV="test"

LOGS_DIR=/home/axmvse/logs
DATE=$(date +"%Y_%m_%d_%H_%M_%s")
ERR="/home/axmvse/logs/err_test_$DATE.log"
LOG="/home/axmvse/logs/log_test_$DATE.log"

bundle
rake run run:stats 1>$LOG 2>$ERR

#Email the status report
#To the most recent committer, and andy
RECIPIENTS=$(git log -1 --pretty="%ae,andy.meneely@gmail.com")

rm /tmp/email.txt
echo -e "\n\n\n\n\n----------------git log -5 --stat------------------------\n\n\n\n\n" >> /tmp/email.txt
git log -5 --stat >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stdout------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $LOG >> /tmp/email.txt
echo -e "\n\n\n\n\n----------------stderr------------------------\n\n\n\n\n" >> /tmp/email.txt
cat $ERR >> /tmp/email.txt
cat /tmp/email.txt | /usr/bin/mail $RECIPIENTS -s "[Chromium History Build] Test Build"
