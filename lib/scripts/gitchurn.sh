#!/bin/bash
# Assumes that the first command line argument is a file with just Git revisions
# Assumes that the directory structure is:
# 	developer-activity-metrics/
#		src/main/sh/		<-- where git-interaction-churn.rb is
#	httpd/
#		git/ 			<-- httpd git repository
#		httpd-history/
#			src/main/sh/ 	<--where this script is
#
# Assume that we are in httpd,
#
# A typical run;
#
# httpd-history/src/main/sh/gitchurn.sh ../revisions.txt 1>httpd-data/httpd-churnlog.txt 2>gitchurn.err
#
# Output is piped to httpd-data/httpd-churnlog.txt
# Errors are piped to gitchurn.err
# Note that revisions.txt is in the current directory, but then you have to specify ../revisions.txt becuase it cd's to 

cd src/
SEP=""

echo -n "["
while IFS=$'\n' read -r rev
do
  for file in `git show --pretty="format:" --name-only $rev`
  do
    if  echo "$file" | grep -Eq "*.(h|cc|js|cpp|gyp|py|c|make|sh|S|scons|sb)$|Makefile$" 
    then  
      echo -n $SEP
      ../../../home/kd9205/chromium/history/lib/scripts/git-interaction-churn.rb $rev $file
      SEP=","
    fi
  done
done<"$1"
echo -n "]"
