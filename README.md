chromium-history
================

Scripts and build system for analysis of Chromium History.

http://se.rit.edu/~archeology

**NOTE:** The following instructions use indirectly use the shell scripts inside the setup folder. These were made for the Vagrant target box which is Ubuntu 12.04 (Precise64). These install scripts will work on the production box without much alteration, but production is one Ubuntu version ahead at 14.04(Trusty64). 

Setup Instructions
==================

1. Download and install both [Vagrant](https://www.vagrantup.com/downloads.html) and [virtualbox](https://www.virtualbox.org/wiki/Downloads)
2. Create a user environment variable called VBOX_USER_HOME and set it to a folder where you want virtualbox to store its config files. Create an environment variable called VAGRANT_HOME and set it a folder where you want to store your virtual container files.
3. Open up the newly installed virtualbox GUI. Go to file and then preferences. In the general tab change the "Default Machine Folder" location to a directory where you want to store your VMs.
4. Clone this repo
5. Open a terminal (In windows use either cygwin or git bash) in the directory of the repo you just cloned.
**NOTE** If you are running on windows you will have to manually start a ssh agent. Run `eval $(ssh-agent)` followed by `ssh-add <path to ssh private key>` (you can leave off the path if your key is call id_rsa). If you may be asked for the passphrase for your key. Then run `ssh-add -l` if this prints out a hash then you have succeeded, else you may need to make a ssh key.There is a tutorial on this [here](https://help.github.com/articles/generating-ssh-keys/) You need to add the `eval $(ssh-agent)` and `ssh-add` commands to your bash_profile if you don't want to run this everytime you bring up the box. More info on this [here](http://www.phase2technology.com/blog/running-an-ssh-agent-with-vagrant/)
6. Run: `vagrant up`, which will download a vm image and install all of the dependencies of this project.
7. Once the installation is complete run: `vagrant ssh`, and this will ssh you into the new box. (If you run into issues here you may not have openssh in your path. Add the git bin tools to your system path to fix this.) 
8. Now you need to create your data.yml, database.yml, and credentials.yml files based of their defaults in the config folder. Since this is development the data.yml isn't as important. 
9. In the database.yml change both the username and password to "vagrant". 
10. In the credentials.yml provide gmail credentials so that the script can access our vulnerability spreadsheet. (We should update this to use OAuth instead). 
11. In the terminal that is ssh-ed into the vagrant box `cd chromium-history` and run `bundle install`. This will install all of the gems for the project. 
12. The environment variable RAILS\_ENV will be set to "development" by default. To change it you need to specify a different environment like: `export RAILS_ENV=test`. Doing this only resets the environment variable for this bash session. To have this set automatically when you ssh in, add the command to your .bashrc file. 
13. Now run: `rake run`. This command will attempt to build project. If you see an erros about invalid postgresql username or password you may need to delete the other environment entries in your database.yml file. There is a mysterious bug where it will pick up the values for another environment. 

For a full list of vagrant commands go [here](https://docs.vagrantup.com/v2/cli/index.html)
