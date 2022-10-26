#!/bin/bash

#installing amass
sleep 2
printf '\nInstaling Amass 3.20.0 \n' | pv -qL 50 | lolcat
cd /opt/
wget https://github.com/OWASP/Amass/releases/download/v3.20.0/amass_linux_amd64.zip
unzip amass_linux_amd64.zip
rm amass_linux_amd64.zip
cp amass_linux_amd64/amass /usr/local/bin/
cd ..
mkdir /root/.config
mkdir /root/.config/amass
touch /root/.config/amass/config.ini

#installing go
printf '\nInstalling Golang 1.19.1\n' | pv -qL 50 | lolcat
sleep 2
wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
source /root/.profile
go version

printf '\nSetting up GOPATH\n' | pv -qL 50 | lolcat
sleep 2
echo 'export PATH=$PATH:/root/go/bin' >> /root/.bashrc
echo 'export GOPATH=/root/go' >> /root/.bashrc
source /root/.profile

printf '\Cloning DNSValidator\n' | pv -qL 50 | lolcat
sleep 2
cd /opt/
git clone https://github.com/vortexau/dnsvalidator.git
cd dnsvalidator
python3 setup.py install
cd ../..

#installing anew
printf '\nAnew\n' | pv -qL 50 | lolcat
sleep 2
go install -v github.com/tomnomnom/anew@latest

printf '\nHTTPX\n' | pv -qL 50 | lolcat
sleep 2
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

printf '\nSubfinder\n' | pv -qL 50 | lolcat
sleep 2
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

printf '\nAssetfinder\n' | pv -qL 50 | lolcat
sleep 2
go install github.com/tomnomnom/assetfinder@latest
