#!/bin/bash

GIT_SRC=~/chromium/src
COMMITS=~/chromium/history/data/dev-commits.txt
OUTPUT=~/chromium/history/data/development/chromium-gitlog.txt

cd $GIT_SRC

for COMMIT in $(cat $COMMITS)
do
    git log -1 --pretty=format:":::%n%H%n%an%n%ae%n%ad%n%P%n%s%n%b" --stat --stat-width=300 --stat-name-width=300 --ignore-space-change $COMMIT > $OUTPUT
done
