#!/bin/bash

GIT_SRC=~/chromium/src
COMMITS=~/chromium/testdata/random-commits.txt
OUTPUT=~/chromium/testdata/chromium-gitlog.txt

cd $GIT_SRC

for COMMIT in $(cat $COMMITS)
do
    git log -1 --pretty=format:":::%n%H%n%an%n%ae%n%ad%n%P%n%s%n%b" --stat --ignore-space-change $COMMIT >> $OUTPUT
done
