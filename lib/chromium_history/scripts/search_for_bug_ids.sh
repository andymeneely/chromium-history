#!/bin/bash

while read i; do
    echo "---For bug $i---"
    psql -U archeology chromium_real -c "SELECT issue FROM code_reviews WHERE description ~ '(\D|\A)$i(\D|\Z)'"
    psql -U archeology chromium_real -c "SELECT issue FROM comments WHERE description ~ '(\D|\A)$i(\D|\Z)'"
    psql -U archeology chromium_real -c "SELECT issue FROM messages WHERE description ~ '(\D|\A)$i(\D|\Z)'"
    echo "----------------"
done < google_ids.txt
