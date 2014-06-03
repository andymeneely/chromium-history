#!/bin/bash

# We're defining Jan 28 2011 as our release date
# Manual inspection of that git log makes the official commit as being 
#   c1bf8951e07a42ecc493ed2e4481211dabbc5f61

# Use git ls-tree and then just take the filename part of the output with awk
# Note that Release v11 is hardcoded into that print command

COMMIT=c1bf8951e07a42ecc493ed2e4481211dabbc5f61
git ls-tree --full-tree -r $COMMIT | awk -v OFS=',' '{print "11.0",$4}'
