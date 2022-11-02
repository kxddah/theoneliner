#!/bin/bash

#Need not run this one, I usually use this on a fresh VPS instance, included in this repo for my convenience 
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get install -y python3
sudo apt-get install -y python3-pip
sudo apt-get install -y unzip
sudo apt-get install -y git
sudo apt-get install -y moreutils
sudo apt install -y lolcat
sudo apt install -y fortune
sudo apt install -y pv

lolcat=/usr/games/lolcat
fortune=/usr/games/fortune

#installing amass
sleep 2
printf '\nInstalling Amass\n' | pv -qL 50 | $lolcat
sleep 5
cd /opt/
wget https://github.com/OWASP/Amass/releases/download/v3.20.0/amass_linux_amd64.zip
unzip amass_linux_amd64.zip
rm amass_linux_amd64.zip
cp amass_linux_amd64/amass /usr/local/bin/
cd ..
mkdir ~/.config
mkdir ~/.config/amass
touch ~/.config/amass/config.ini

#installing go
sleep 2
printf '\nInstalling Golang\n' | pv -qL 50 | $lolcat
sleep 5
wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
source ~/.profile
go version

sleep 2
printf '\nInstalling ffuf\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/ffuf/ffuf@latest

sleep 2
printf '\nSetting up GOPATH\n' | pv -qL 50 | $lolcat
sleep 5
echo 'export PATH=$PATH:/root/go/bin' >> /root/.bashrc
echo 'export GOPATH=/root/go' >> /root/.bashrc
source ~/.profile

sleep 2
printf '\nInstalling DNSValidator\n' | pv -qL 50 | $lolcat
sleep 5
cd /opt/
git clone https://github.com/vortexau/dnsvalidator.git
cd dnsvalidator
python3 setup.py install
cd /

sleep 2
printf '\nInstalling httpx\n' | pv -qL 50 | $lolcat
sleep 5
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

sleep 2
printf '\nInstalling meg\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/tomnomnom/meg@latest

sleep 2
printf '\nInstalling Subfinder\n' | pv -qL 50 | $lolcat
sleep 5
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

sleep 2
printf '\nInstalling Gospider\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/jaeles-project/gospider@latest

sleep 2
printf '\nInstalling Gau\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/lc/gau/v2/cmd/gau@latest

sleep 2
printf '\nInstalling Assetfinder\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/tomnomnom/assetfinder@latest

sleep 2
printf '\nInstalling Hakrawler\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/hakluke/hakrawler@latest

sleep 2
printf '\nInstalling ASNmap\n' | pv -qL 50 | $lolcat
sleep 5
go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest

sleep 2
printf '\nInstalling Aquatone\n' | pv -qL 50 | $lolcat
sleep 5
apt-get install -y chromium
cd /opt
wget https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip
unzip aquatone_linux_amd64_1.7.0.zip
rm LICENSE.txt README.md aquatone_linux_amd64_1.7.0.zip
cp aquatone /usr/local/bin/
cd /opt

sleep 2
printf '\nInstalling ReconFTW\n' | pv -qL 50 | $lolcat
sleep 5
git clone https://github.com/six2dez/reconftw
cd reconftw/
./install.sh

sleep 2
printf '\nInstalling Waymore\n' | pv -qL 50 | $lolcat
sleep 5
cd /opt/
git clone https://github.com/xnl-h4ck3r/waymore.git
cd waymore
sudo pip3 install -r requirements.txt
sudo python setup.py install

sleep 2
printf '\nInstalling Anew\n' | pv -qL 50 | $lolcat
sleep 5
go install -v github.com/tomnomnom/anew@latest

sleep 2
printf '\nInstalling nuclei\n' | pv -qL 50 | $lolcat
sleep 5
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest


#add option for yes or no, for both wordlist
sleep 2
printf '\nDownloading Seclist and Assetnote wordlists\n' | pv -qL 50 | $lolcat
sleep 5
cd /
mkdir bounty
cd bounty/
mkdir wordlists
cd wordlists/
git clone https://github.com/danielmiessler/SecLists.git
wget -r --no-parent -R "index.html*" https://wordlists-cdn.assetnote.io/data/ -nH 

sleep 2
printf '\nHappy Hacking :)\n' | pv -qL 40 | $lolcat
sleep 5
