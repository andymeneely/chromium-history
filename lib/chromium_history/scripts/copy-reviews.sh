#!/bin/bash -x

IDS=~/chromium/testdata/reviews-of-random-commits.txt
REAL_DATA=~/chromium/realdata
TEST_DATA=~/chromium/testdata

for ID in $(cat $IDS)
do
    
    cp -r "$REAL_DATA/codereviews/$ID.json" $TEST_DATA/codereviews
    cp -r "$REAL_DATA/codereviews/$ID" $TEST_DATA/codereviews
done
    
