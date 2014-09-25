#!/bin/bash

# When you run this in chromium/src make sure to run in the following way:
# ../history/lib/scripts/sloc.sh X.X
# where X.X is the release number.
# EX:  ../history/lib/scripts/sloc.sh 11.0
#
# This names the file created from this script X.X.csv
# In the example the output file would be named 11.0.csv

# outputs language,filename,blank,comment,code
#
# --skip-uniqueness because some files are repeated but with different paths
# (but then we have to sort and uniq them to remove duplicate lines)
#
# Chop off the top two header rows too (three newlines)
cloc --by-file --force-lang="Lisp",sb --force-lang="Python",gyp --force-lang="Python",scons --progress-rate=0 --quiet --csv --skip-uniqueness . | tail -n +3 - | sort | uniq > $1.csv
