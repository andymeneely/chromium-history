#!/bin/bash

#Get the table to stdout
psql chromium_real -c "COPY release_filepaths TO STDOUT WITH CSV HEADER"
