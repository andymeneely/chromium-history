#!/bin/bash
load_csv () {
    psql chromium_history -c "COPY raw_files FROM '/home/vagrant/data/list.csv' DELIMITER ',' CSV;"
}

load_cr () {
    psql chromium_history -c "COPY code_reviews FROM '/home/vagrant/data/code_reviews.csv' DELIMITER ',' CSV;"
    psql chromium_history -c "ALTER TABLE code_reviews ADD COLUMN id SERIAL; ALTER TABLE code_reviews ADD PRIMARY KEY (id);"
    psql chromium_history -c "COPY reviewers FROM '/home/vagrant/data/reviewers.csv' DELIMITER ',' CSV;"
    psql chromium_history -c "ALTER TABLE reviewers ADD COLUMN dev_id integer; CREATE INDEX zed ON reviewers USING hash (issue);"
    
    psql chromium_history -c "COPY patch_sets FROM '/home/vagrant/data/patch_sets.csv' DELIMITER ',' CSV;"
    
    psql chromium_history -c "COPY messages FROM '/home/vagrant/data/messages.csv' DELIMITER ',' CSV;"
    
    psql chromium_history -c "COPY patch_set_files FROM '/home/vagrant/data/patch_set_files.csv' DELIMITER ',' CSV;"
    
    psql chromium_history -c "COPY comments FROM '/home/vagrant/data/comments.csv' DELIMITER ',' CSV;"
}

add_ids () {
    psql chromium_history -c "ALTER TABLE raw_files ADD COLUMN id SERIAL;
   ALTER TABLE raw_files ADD PRIMARY KEY (id);"
}

load_code_reviews () {
    export RAILS_ENV=production 
    rake run:batch
}

# load_csv
# add_ids
load_cr
load_code_reviews