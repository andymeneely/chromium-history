#!/bin/bash

# outputs language,filename,blank,comment,code
# into a csv
#
# --skip-uniqueness because some files are repeated but with different paths
# (but then we have to sort and uniq them to remove duplicate lines)
#
# Chop off the top two header rows too
cloc --by-file --progress-rate=0 --quiet --csv --skip-uniqueness . | tail -n +2 | sort | uniq > sloc.csv
