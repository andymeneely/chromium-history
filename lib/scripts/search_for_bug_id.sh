#!/bin/bash

psql -U archeology chromium_real -c "SELECT issue FROM code_reviews WHERE description ~ '(\D|\A)$1(\D|\Z)'"
psql -U archeology chromium_real -c "SELECT patch_set_file_id FROM comments WHERE text ~ '(\D|\A)$1(\D|\Z)'"
psql -U archeology chromium_real -c "SELECT code_review_id FROM messages WHERE text ~ '(\D|\A)$1(\D|\Z)'"
