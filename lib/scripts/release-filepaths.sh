#!/bin/bash

# We use this script to collect the snapshot of files in the tree at the time of a given release
# The following commits are what we consider the "release" snapshot. They are based on major releases about a year apart
# Yes, Chromium releases more often, but our analysis only focuses on yearly cycles.

#Usage:
# Modify the variables below with whatever variable pair you need
# (cd into the src directory of the chromium git tree)
# e.g. 
#   ../history/lib/scripts/release-filepaths.sh > ../realdata/releases/5.0.csv
# 

# One of the earliest major releases was 5.0.306.0
# Jan 26 2010
#COMMIT=7c4ea146bc033d89c1a0d527ae3d43b587a23cab
#RELEASE=5.0

# We're defining Jan 28 2011 as our release date
# Manual inspection of that git log makes the official commit as being 
#
#COMMIT=c1bf8951e07a42ecc493ed2e4481211dabbc5f61
#RELEASE=11.0

# For a second release, we're using Feb 2 2012 as another release date of 19.0
# Manual inspection of git makes that official commit as being
#
#COMMIT=d653361472c0f286b260f68d5032173d505661b1
#RELEASE=19.0

# Next one is Feb 14 2013
#COMMIT=d572bfd0d4688449141d9de6a65792b2ece5e683
#RELEASE=27.0

# Feb 20 2014
COMMIT=00404744a13c38f24fc6f6c537558eb55245abea
RELEASE=35.0

# Use git ls-tree and then just take the filename part of the output with awk
# Note that Release v11 is hardcoded into that print command
DATE=`git log -1 --pretty='%aD' $COMMIT`
git ls-tree --full-tree -r $COMMIT | awk -v OFS=',' -v R=$RELEASE -v D="\"$DATE\"" '{print R,D,$4}'
