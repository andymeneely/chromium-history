#!/bin/bash
apt-get update -y
apt-get install vim -y
apt-get install git -y
apt-get install r-base -y

apt-get --purge remove ruby-rvm -y
rm -f /usr/share/ruby-rvm /etc/rvmrc /etc/profile.d/rvm.sh

apt-get install curl -y

\curl -L https://get.rvm.io | bash -s stable --ruby --autolibs=enable --auto-dotfiles 

source /etc/profile.d/rvm.sh

rvm install ruby-1.9.3
rvm use --default 1.9.3
apt-get install libpq-dev -y
apt-get install nodejs -y

cd /home/vagrant/chromium-history
gem install --no-rdoc --no-ri rails 
gem install --no-rdoc --no-ri bundler

update-locale LANG=en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8
. /etc/default/locale

apt-get install postgresql postgresql-contrib -y
sudo -u postgres createuser --superuser vagrant
sudo -u postgres psql -U postgres -d postgres -c "alter user vagrant with password 'vagrant';"

bundle install