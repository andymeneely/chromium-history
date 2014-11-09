#!/bin/bash
function update() {
  sudo apt-get update -y
}

function common() {
  update
  sudo apt-get install -y r-base openjdk-7-jdk python-dev unzip vim wget git-core curl libpq-dev zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties
}

function postgresql() {
  sudo update-locale LANG=en_US.UTF-8
  sudo update-locale LC_ALL=en_US.UTF-8
  . /etc/default/locale
  sudo apt-get install postgresql postgresql-contrib -y
}

function vagrantPostgresql() {
  sudo -u postgres createuser --superuser vagrant
  sudo -u postgres psql -U postgres -d postgres -c "alter user vagrant with password 'vagrant';"
}

function rvm() {
  sudo apt-get -y install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
  curl -L https://get.rvm.io | bash -s stable
  source ~/.rvm/scripts/rvm
  echo "source ~/.rvm/scripts/rvm" >> ~/.bashrc

  rvm install ruby-1.9.3
  rvm use --default 1.9.3
  sudo apt-get install libpq-dev -y
}

function rbenv() {
  curl https://raw.githubusercontent.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
  cp /vagrant/setup/.bash_aliases ~/
  source ~/.bashrc
  rbenv bootstrap-ubuntu-14-04
  rbenv install 1.9.3-p392
  rbenv rehash
  rbenv global 1.9.3-p392
}

function rails() {
  node
  pushd /home/vagrant/chromium-history
  gem install --no-rdoc --no-ri bundlervag
  gem install --no-rdoc --no-ri rake 
  gem install --no-rdoc --no-ri rails
  popd
}

function treatDeps() {
  wget http://louismullie.com/treat/stanford-core-nlp-full.zip 
  sudo unzip stanford-core-nlp-full.zip -d /opt/stanford-core-nlp

  wget http://louismullie.com/treat/punkt/english.yaml
  sudo mkdir /opt/punkt
  sudo chmod 777 /opt/punkt
  mv english.yaml /opt/punkt/
}

function node() {
  sudo apt-add-repository -y ppa:chris-lea/node.js
  update
  sudo apt-get -y install nodejs
}

function environmentVars() {
  sudo cp /vagrant/setup/chromium_history.sh /etc/profile.d/
}

function nltk() {
  sudo apt-get -y install python-setuptools
  sudo easy_install pip 
  sudo pip install -U numpy
  sudo pip install -U nltk
  python -m nltk.downloader all
}

function lineSep() {
  for n in {1..20}
  do
    printf "="
  done
  printf "\n"
}

function title() {
  lineSep
  echo "$1"
  lineSep
}

set -e
title "Installing Everything"
common

title "Installing Postgresql"
vagrantPostgresql

title "Installing NLTK"
nltk

environmentVars

title "Finished Everything"
