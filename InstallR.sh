#!/bin/sh
##
## InstallR.sh for use on Amazon EC2
##
## Jay Emerson and Susan Wang, May 2013,.. Modified by Dipanjan Paul, 2014
##
## Added "doextras" for Apache, Rserve/FastRWeb, Shiny server (JE June 2013)
##
## -------------------------
## To log in the first time:
#
## ssh -i ~/.ssh/jaykey.pem ubuntu@HOSTNAME
##
## sudo su
## wget http://www.stat.yale.edu/~jay/EC2/InstallR.sh
## chmod +x InstallR.sh
## ./InstallR.sh
##

## Set some variables here:

debsource1='deb http://cran.cnr.Berkeley.edu/bin/linux/ubuntu precise/'
debsource2='deb http://cran.cnr.Berkeley.edu/bin/linux/ubuntu trusty/'
debsource3='deb http://cran.cnr.Berkeley.edu/bin/linux/ubuntu lucid/'

fastrweb='/usr/local/lib/R/site-library/FastRWeb'
doextras=0           # 0 if you don't want apache, LaTeX, Rserve/FastRWeb, shiny

## Choose the R version here:

#rversion='2.15.3-1precise0precise1'
#rversion='3.0.1-1precise0precise2'

# Get this and modify by hand for further package customization:
wget https://raw.githubusercontent.com/dpaul004/General/master/InstallPackages.R

## ----------------------------------------------------------------------------
## - Probably don't modify, below
## ----------------------------------------------------------------------------

echo ${debsource1} >> /etc/apt/sources.list
echo ${debsource2} >> /etc/apt/sources.list
echo ${debsource3} >> /etc/apt/sources.list


apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
apt-get update

echo "\n\nFinished update, installing R...\n\n"

apt-get -y --force-yes install r-base r-recommended r-base-dev
apt-get -y --force-yes install r-base-core


if [ $doextras = 1 ] ; then

  wget http://www.stat.yale.edu/~jay/EC2/InstallExtras.R
  
  echo "\n\nFinished R, doing LaTeX and Apache...\n\n"

  apt-get -y --force-yes install texlive-latex-base
  apt-get -y --force-yes install apache2
  apt-get -y --force-yes install libcairo2-dev

  echo "\n\nFinished LaTeX and Apache.\n\n"
  echo "\n\nDoing libxt, Rserve, FastRWeb, knitr, ...\n\n"

  apt-get -y --force-yes install libxt-dev
  R CMD BATCH InstallExtras.R        # Rserve, FastRWeb, knitr

fi

R CMD BATCH InstallPackages.R        # bigmemory, foreach, ...

if [ $doextras = 1 ] ; then

  wget http://www.stat.yale.edu/~jay/EC2/InstallShiny.R
  
  echo "\n\nDoing Shiney and FastRWeb postinstallation.\n\n"
  
  # FastRWeb configuration
  cd ${fastrweb}
  sh ./install.sh
  cp Rcgi/Rcgi /usr/lib/cgi-bin/R
  cd /home/ubuntu

  echo '#!/usr/bin/perl' > /usr/lib/cgi-bin/foo.cgi
  echo 'print "Content-type: text/html\n\n";' >> /usr/lib/cgi-bin/foo.cgi
  echo 'print "Hello World from a Perl test CGI script.";' >> /usr/lib/cgi-bin/foo.cgi
  chmod +x /usr/lib/cgi-bin/foo.cgi

  /var/FastRWeb/code/start

  # Shiny:
  apt-get update
  apt-get -y --force-yes install python-software-properties python g++ make
  add-apt-repository ppa:chris-lea/node.js
  apt-get update
  apt-get -y --force-yes install nodejs
  R CMD BATCH InstallShiny.R
  npm install -g shiny-server
  
  wget https://raw.github.com/rstudio/shiny-server/master/config/upstart/shiny-server.conf -O /etc/init/shiny-server.conf
  
  useradd -r shiny
  mkdir -p /var/shiny-server/www
  mkdir -p /var/shiny-server/log
  cp -rp /usr/local/lib/R/site-library/shiny/examples /var/shiny-server/www
  
  start shiny-server

fi

mkdir /mnt/test
chown ubuntu:ubuntu /mnt/test

echo "Installation complete\n"
echo "Test CGI script at http://host/cgi-bin/foo.cgi.\n"
echo "Test FastRWeb at http://host/cgi-bin/R/main.\n"
echo "Test Shiny at http://host:3838 after starting up shiny-server as root.\n"



