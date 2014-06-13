#!/bin/bash

# outputs language,filename,blank,comment,code
# into a csv
cloc --by-file --progress-rate=0 --quiet --csv . > sloc.csv
