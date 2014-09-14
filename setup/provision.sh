#!/bin/bash
sudo apt-get update -y
sudo apt-get install vim -y
sudo apt-get install git -y
sudo apt-get install r-base -y
sudo apt-get install openjdk-7-jdk -y

sudo apt-get --purge remove ruby-rvm -y
sudo rm -f /usr/share/ruby-rvm /etc/rvmrc /etc/profile.d/rvm.sh

sudo apt-get install curl -y

\curl -L https://get.rvm.io | bash -s stable --ruby --autolibs=enable --auto-dotfiles 

source /home/vagrant/.rvm/scripts/rvm

rvm install ruby-1.9.3
rvm use --default 1.9.3
sudo apt-get install libpq-dev -y
sudo apt-get install nodejs -y

cd /home/vagrant/chromium-history
gem install --no-rdoc --no-ri rails 
gem install --no-rdoc --no-ri bundler

sudo update-locale LANG=en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8
. /etc/default/locale

sudo apt-get install postgresql postgresql-contrib -y
sudo -u postgres createuser --superuser vagrant
sudo -u postgres psql -U postgres -d postgres -c "alter user vagrant with password 'vagrant';"

sudo cp /vagrant/setup/chromium_history.sh /etc/profile.d/
