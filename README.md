chromium-history
================

Scripts and build system for analysis of Chromium History.

http://se.rit.edu/~archeology

Setup Instructions
==================

1. Download and install both [Vagrant](https://www.vagrantup.com/downloads.html) and [virtualbox](https://www.virtualbox.org/wiki/Downloads)
2. Clone this repo
3. Open a terminal (command line for windows) in the directory of the repo you just cloned.
4. Run: `vagrant up`, which will download a vm image and install all of the dependencies of this project.
5. Once the installation is complete run: `vagrant ssh`, and this will ssh you into the new box. (If you run into issues here you may not have openssh in your path. Add the git bin tools to your system path to fix this.) 
6. Donezo
