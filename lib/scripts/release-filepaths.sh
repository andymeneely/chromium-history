#!/bin/bash

# We're defining Jan 28 2011 as our release date
# Manual inspection of that git log makes the official commit as being 
#
COMMIT=c1bf8951e07a42ecc493ed2e4481211dabbc5f61
RELEASE=11.0

# For a second release, we're using Feb 2 2012 as another release date of 19.0
# Manual inspection of git makes that official commit as being
#
#COMMIT=d653361472c0f286b260f68d5032173d505661b1
#RELEASE=19.0

# Use git ls-tree and then just take the filename part of the output with awk
# Note that Release v11 is hardcoded into that print command
DATE=`git log -1 --pretty='%aD' $COMMIT`
git ls-tree --full-tree -r $COMMIT | awk -v OFS=',' -v R=$RELEASE -v D="\"$DATE\"" '{print R,D,$4}'
