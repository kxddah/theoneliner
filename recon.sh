#!/bin/bash

#need to add flags to skip tools, stdin files

#reading the value of ASN and IP file
lolcat=/usr/games/lolcat
fortune=/usr/games/fortune
value=$(<bgp.txt)

#saving asns and ipranges in vars
asn=$(echo "$value" | awk '{print $1}' | awk '/A/ {print}' | paste -sd,)
ipranges=$(echo "$value" | awk '{print $1}' | awk '!/A/ {print}' | paste -sd,)

#gathering input on scope
validate="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"
echo "Enter domain to scan: "
read domain
if [[ -z "$domain" ]]
then
	echo "Domain value can't be empty! Exiting..." && exit 1
elif [[ ! "$domain" =~ $validate ]];
then
	echo "Invalid domain name! Exiting..." && exit 1
fi
printf '\n'

#making directory for target
mkdir $domain
cd $domain

echo '████████╗██╗░░██╗███████╗░█████╗░███╗░░██╗███████╗██╗░░░░░██╗███╗░░██╗███████╗██████╗░'| $lolcat
echo '╚══██╔══╝██║░░██║██╔════╝██╔══██╗████╗░██║██╔════╝██║░░░░░██║████╗░██║██╔════╝██╔══██╗'| $lolcat
echo '░░░██║░░░███████║█████╗░░██║░░██║██╔██╗██║█████╗░░██║░░░░░██║██╔██╗██║█████╗░░██████╔╝'| $lolcat
echo '░░░██║░░░██╔══██║██╔══╝░░██║░░██║██║╚████║██╔══╝░░██║░░░░░██║██║╚████║██╔══╝░░██╔══██╗'| $lolcat
echo '░░░██║░░░██║░░██║███████╗╚█████╔╝██║░╚███║███████╗███████╗██║██║░╚███║███████╗██║░░██║'| $lolcat
echo '░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚══╝╚══════╝╚══════╝╚═╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝'| $lolcat
printf '\n\n'
$fortune | $lolcat
printf '\n\n'

#dnsvalidator
sleep 2
printf '\nCollecting DNS resolvers using DNSValidator\n' | pv -qL 50 | $lolcat
sleep 5

dnsvalidator -tL https://public-dns.info/nameservers.txt -threads 150 -o resolvers.txt
sort -R resolvers.txt | tail -n 50 > 50resolvers.txt
rm resolvers.txt

#amass
sleep 2
printf '\nRunning Amass Intel\n' | pv -qL 50 | $lolcat
sleep 5

if [[ ! -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -cidr $ipranges -rf 50resolvers.txt -config /root/.config/amass/config.ini -o amassintel.txt
elif [[ ! -z $asn && -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -rf 50resolvers.txt -config /root/.config/amass/config.ini -o amassintel.txt
elif [[ -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -cidr $ipranges -rf 50resolvers.txt -config /root/.config/amass/config.ini -o amassintel.txt
else
	amass intel -active -whois -d $domain -rf 50resolvers.txt -config /root/.config/amass/config.ini -o amassintel.txt
fi

#filter results from amass intel file
cat amassintel.txt | grep $domain | tee subdomains.txt
rm amassintel.txt


#amass enum
sleep 2
printf '\nRunning Amass Enum\n' | pv -qL 50 | $lolcat
sleep 5

#don't use subdomains.txt if 0 results from intel
if [[ -s subdomains.txt ]]
then
	amass enum -active -d $domain -nf subdomains.txt -rf 50resolvers.txt -config /root/.config/amass/config.ini -nocolor -o amassenum.txt
else
	amass enum -active -d $domain -rf 50resolvers.txt -config /root/.config/amass/config.ini -nocolor -o amassenum.txt
fi

#filter results from amass enum file 
cat amassenum.txt | grep $domain | anew subdomains.txt
rm amassenum.txt

#Running subfinder
sleep 2
printf '\nRunning Subfinder\n' | pv -qL 50 | $lolcat
sleep 5

subfinder -dL subdomains.txt -all -o subfinder.txt -pc ~/.config/subfinder/provider-config.yaml -rL 50resolvers.txt -nc

#combining results from subfinder into final file
cat subfinder.txt | grep $domain | anew subdomains.txt
rm subfinder.txt

#Running assetfinder
sleep 2
printf '\nRunning Assetfinder\n' | pv -qL 50 | $lolcat
sleep 5

touch assetfinder.txt
assetfinder $domain | tee assetfinder.txt

#combining results from assetfinder to the final list
cat assetfinder.txt | grep $domain | anew subdomains.txt
rm assetfinder.txt

#Running httpx
sleep 2
printf '\nFiltering valid domains using HTTPX\n' | pv -qL 50 | $lolcat
sleep 5

touch resolvedsubs.txt
httpx -l subdomains.txt -fc 404 -silent -rl 10 -timeout 15 -o resolvedsubs.txt

#filtering httpx output to remove http(s)://, requires moreutils, apt-get install moreutils
cat resolvedsubs.txt | cut -d "/" -f 3 | sponge resolvedsubs.txt
