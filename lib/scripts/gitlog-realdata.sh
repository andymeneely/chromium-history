#!/bin/bash

GIT_SRC=~/chromium/src
OUTPUT=~/chromium/realdata/chromium-gitlog.txt

cd $GIT_SRC

git log --pretty=format:":::%n%H%n%an%n%ae%n%ad%n%P%n%s%n%b;;;" --stat --stat-width=300 --stat-name-width=300 --ignore-space-change > $OUTPUT

ll $OUTPUT
