#!/bin/bash

#creating paths
# Get the current shell
current_shell=$(echo $SHELL)
if [[ $current_shell == *"zsh"* ]]; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
     echo 'export PATH=$PATH:~/go/bin/' >> ~/.zshrc
     echo 'export PATH=$PATH:/root/.pdtm/go/bin' >> ~/.zshrc
     source ~/.zshrc

elif [[ $current_shell == *"bash"* ]]; then
     echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
     echo 'export PATH=$PATH:~/go/bin/' >> ~/.bashrc
     echo 'export PATH=$PATH:/root/.pdtm/go/bin' >> ~/.bashrc
     source ~/.bashrc

else
    echo "Please set the paths for your shell: $current_shell"
fi

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
sudo apt-get install -y jq
sudo apt install -y crunch

lolcat=/usr/games/lolcat
fortune=/usr/games/fortune

wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source ~/.profile
GO_OUTPUT=$(go version)
if [[ "$GO_OUTPUT" == go\ version* ]]; then
    echo "Go Installed"
else
    echo "Error installing Go"
    exit 1
fi
rm go1.22.5.linux-amd64.tar.gz

go install -v github.com/owasp-amass/amass/v4/...@master
mkdir ~/.config && mkdir ~/.config/amass
curl -o ~/.config/amass/datasources.yaml https://raw.githubusercontent.com/owasp-amass/amass/master/examples/datasources.yaml
curl -o ~/.config/amass/config.yaml https://raw.githubusercontent.com/owasp-amass/amass/master/examples/config.yaml

go install github.com/ffuf/ffuf/v2@latest

go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
pdtm -ia
mkdir ~/.config/subfinder
curl -o ~/.config/subfinder/provider-config.yaml https://raw.githubusercontent.com/kxddah/theoneliner/main/subfinder-provider-config.yaml
mkdir ~/.config/notify
curl -o ~/.config/notify/provider-config.yaml https://raw.githubusercontent.com/projectdiscovery/notify/328cc3d7d1f376759182a123764dd5f5a36ec654/cmd/integration-test/test-config.yaml

source ~/.zshrc
source ~/.bashrc
go install github.com/tomnomnom/meg@latest
go install github.com/jaeles-project/gospider@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/hakluke/hakrawler@latest
go install github.com/tomnomnom/waybackurls@latest
go install -v github.com/tomnomnom/anew@latest
go install github.com/bitquark/shortscan/cmd/shortscan@latest
go install github.com/BishopFox/jsluice/cmd/jsluice@latest
go install github.com/hahwul/dalfox/v2@latest

curl -o ~/.gau.toml https://raw.githubusercontent.com/lc/gau/master/.gau.toml

cd /opt/
git clone https://github.com/vortexau/dnsvalidator.git
cd dnsvalidator
python3 setup.py install

cd /opt/
git clone https://github.com/EnableSecurity/wafw00f.git
cd wafw00f
python3 setup.py install

cd /opt/
git clone https://github.com/ticarpi/jwt_tool
cd jwt_tool
python3 -m pip install -r requirements.txt

cd /opt/
git clone https://github.com/defparam/smuggler.git

cd /opt/
git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev

cd /opt/
wget https://caido.download/releases/v0.38.0/caido-cli-v0.38.0-linux-x86_64.tar.gz
tar -xvf caido-cli-v0.38.0-linux-x86_64.tar.gz
rm caido-cli-v0.38.0-linux-x86_64.tar.gz

cd /opt/
curl -sLO https://github.com/epi052/feroxbuster/releases/latest/download/feroxbuster_amd64.deb.zip
unzip feroxbuster_amd64.deb.zip
sudo apt install ./feroxbuster_*_amd64.deb
rm -rf feroxbuster_*_amd64.deb
rm -rf feroxbuster_amd64.deb.zip
rm -rf feroxbuster.tmp0-stripped

cd /opt/
git clone https://github.com/s0md3v/Arjun.git
cd Arjun
python3 setup.py install

cd /opt/
git clone https://github.com/0xacb/recollapse.git
cd recollapse
./install.sh

cd /opt/
wget https://github.com/assetnote/kiterunner/releases/download/v1.0.2/kiterunner_1.0.2_linux_amd64.tar.gz
tar -xvf kiterunner_1.0.2_linux_amd64.tar.gz
mv kr /usr/local/bin
rm kiterunner_1.0.2_linux_amd64.tar.gz

cd /opt/
git clone https://github.com/xnl-h4ck3r/waymore.git
cd waymore
sudo pip3 install -r requirements.txt
sudo python setup.py install
chmod +x /opt/waymore/waymore/waymore.py

cd /opt/
git clone https://github.com/blechschmidt/massdns.git
cd /opt/massdns/
make
cp bin/massdns /usr/local/bin

go install github.com/d3mondev/puredns/v2@latest

printf '\nHappy Hacking :)\n' | pv -qL 40 | $lolcat
sleep 5
