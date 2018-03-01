#!/bin/bash
### Install Java 8 and agree to the license
cd ~
# Requirements
sudo apt -y install aptitude
sudo apt -y install curl
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt update
sudo apt -y install aptitude
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo aptitude -y install oracle-java8-installer
