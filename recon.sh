#!/bin/bash

#Improvement: need to add flags to skip tools, stdin files

lolcat=/usr/games/lolcat
fortune=/usr/games/fortune

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
printf '\n'
echo "Enter organisation name: "
read org
printf '\n'

#making directory for target
mkdir $domain
cd $domain
cp ../params.txt ./


echo '████████╗██╗░░██╗███████╗░█████╗░███╗░░██╗███████╗██╗░░░░░██╗███╗░░██╗███████╗██████╗░'| $lolcat
echo '╚══██╔══╝██║░░██║██╔════╝██╔══██╗████╗░██║██╔════╝██║░░░░░██║████╗░██║██╔════╝██╔══██╗'| $lolcat
echo '░░░██║░░░███████║█████╗░░██║░░██║██╔██╗██║█████╗░░██║░░░░░██║██╔██╗██║█████╗░░██████╔╝'| $lolcat
echo '░░░██║░░░██╔══██║██╔══╝░░██║░░██║██║╚████║██╔══╝░░██║░░░░░██║██║╚████║██╔══╝░░██╔══██╗'| $lolcat
echo '░░░██║░░░██║░░██║███████╗╚█████╔╝██║░╚███║███████╗███████╗██║██║░╚███║███████╗██║░░██║'| $lolcat
echo '░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░╚════╝░╚═╝░░╚══╝╚══════╝╚══════╝╚═╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝'| $lolcat
printf '\n\n'
$fortune | $lolcat
printf '\n\n'

#fetching all asns, not sure if the list is updated, let me know if any better solutions present
value=$(curl https://ftp.ripe.net/ripe/asnames/asn.txt)

#saving asns and ipranges in vars
asn=$(echo "$value" | grep -i "\<"$org"\>" | awk '{print "AS"$1}' | paste -sd,)

#asnmap will probably throw an error, probably cause their api is usually down - https://status.projectdiscovery.io/
if [[ ! -z $asn ]]
then
        ipranges=$(asnmap -asn $(echo $asn))
else
        ipranges=$(asnmap -org $(echo $org))
fi

ipranges=$(echo "$ipranges" | awk '{print $1}' | paste -sd,)

echo -e "ASNs: "$asn"\n"
echo -e "IP/ranges: "$ipranges"\n"

#dnsvalidator
sleep 2
printf '\nCollecting DNS resolvers using DNSValidator\n' | pv -qL 50 | $lolcat
sleep 5

dnsvalidator --silent -tL https://public-dns.info/nameservers.txt -threads 75 | tee resolvers.txt
sort -R resolvers.txt | tail -n 150 > 100resolvers.txt
rm resolvers.txt
mv 100resolvers.txt ../100resolvers.txt
echo -e "DNS Resolvers collected, initating enumeration and scanning" | notify -silent


#amass
sleep 2
printf '\nRunning Amass Intel\n' | pv -qL 50 | $lolcat
sleep 5

if [[ ! -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -cidr $ipranges -timeout 100 -rf ../100resolvers.txt -o amassintel.txt
elif [[ ! -z $asn && -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -timeout 100 -rf ../100resolvers.txt -o amassintel.txt
elif [[ -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -cidr $ipranges -timeout 100 -rf ../100resolvers.txt -o amassintel.txt
else
	amass intel -active -whois -d $domain -rf -timeout 100 ../100resolvers.txt -o amassintel.txt
fi

#filter results from amass intel file
cat amassintel.txt | grep $domain | tee subdomains.txt
rm amassintel.txt


#amass enum
#sleep 2
#printf '\nRunning Amass Enum\n' | pv -qL 50 | $lolcat
#sleep 5

#don't use subdomains.txt if 0 results from intel
#if [[ -s subdomains.txt ]]
#then
#	amass enum -active -d $domain -nf subdomains.txt -rf ../100resolvers.txt -timeout 100 -nocolor -o amassenum.txt
#else
#	amass enum -active -d $domain -rf ../100resolvers.txt -timeout 100 -nocolor -o amassenum.txt
#fi

#filter results from amass enum file 
#cat amassenum.txt | grep $domain | anew subdomains.txt
#rm amassenum.txt

#Running subfinder
sleep 2
printf '\nRunning Subfinder\n' | pv -qL 50 | $lolcat
sleep 5

subfinder -dL subdomains.txt -all -o subfinder.txt -pc ~/.config/subfinder/provider-config.yaml -rL ../100resolvers.txt -nc

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
echo -e "Subdomain enumeration for "$domain" has been completed\n" | notify -silent
echo -e "Total subdomains: $(cat subdomains.txt | wc -l) & Resolved subdomains: $(cat resolvedsubs.txt | wc -l)\n" | notify -silent


#integrating gau, waymore, waybackurls and katana
touch spidering.txt
touch tempfile.txt
#Running gau
sleep 2
printf '\Collecting URLs using GAU\n' | pv -qL 50 | $lolcat
sleep 5
cat subdomains.txt | gau --providers wayback,commoncrawl,otx,urlscan | tee spidering.txt

#Running Katana
#sleep 2
#printf '\nSpidering using Katana\n' | pv -qL 50 | $lolcat
#sleep 5
#katana -list subdomains.txt -d 4 -jc -rl 50 | tee tempfile.txt
#cat tempfile.txt | anew spidering.txt

Running Waymore
sleep 2
printf '\nSpidering using Waymore\n' | pv -qL 50 | $lolcat
sleep 5
#!!!please mention path to your waymore.py file
python3 /opt/waymore/waymore.py -i $domain -mode U | tee tempfile.txt 
cat tempfile.txt | anew spidering.txt

Running waybackurls
sleep 2
printf '\Collecting URLs using waybackurls\n' | pv -qL 50 | $lolcat
sleep 5
cat subdomains.txt | waybackurls > tempfile.txt
cat tempfile.txt | anew spidering.txt


sleep 2
printf '\nSpidering using GoSpider\n' | pv -qL 50 | $lolcat
sleep 5
gospider -S subdomains.txt --js --subs --sitemap -a -w -r -o tempfile.txt
cat tempfile.txt | anew spidering.txt
rm tempfile.txt

#removing duplicate entries
cat spidering.txt | sort -u | uniq | sponge spidering.txt
echo -e "Spidering for "$domain" has been completed, total links found: $(cat spidering.txt | wc -l)\n" | notify -silent


#portscanning
sleep 2
printf '\nPort scanning using Naabu\n' | pv -qL 50 | $lolcat
sleep 5
naabu -l subdomains.txt -p 1-65535 -rate 2000 -timeout 5000 | tee portscan.txt
echo -e "Portscanning for "$domain" has been completed\n" | notify -silent


#Running nuclei on portscanned unresolved hosts
sleep 2
printf '\nVulnerability scanning using Nuclei\n' | pv -qL 50 | $lolcat
sleep 5
nuclei -l portscan.txt -rl 1000 -t ~/nuclei-templates/ | tee nuclei.txt
nucleilow=$(cat nuclei.txt | grep '32mlow' | wc -l)
nucleimedium=$(cat nuclei.txt | grep '33mmedium' | wc -l)
nucleihigh=$(cat nuclei.txt | grep '208mhigh' | wc -l)
echo "Nuclei scan results: High: "$nucleihigh"  Medium: "$nucleimedium"  Low: "$nucleilow"" | notify -silent


#preparing params.txt from spidering.txt
input_file="spidering.txt"
output_file="params1.txt"
awk -F'[=?]' '!seen[$2]++ && $2 { print $2 }' "$input_file" | sort > "$output_file"
cat params1.txt | anew params.txt
awk '{print "https://" $0}' resolvedsubs.txt > resolvedsubswithprotocol.txt

#not entirely sure how dalfox uses mining dict wordlist, will read-up more
sleep 2
printf '\nRunning Dalfox\n' | pv -qL 50 | $lolcat
sleep 5
dalfox file resolvedsubswithprotocol.txt --mining-dict-word params.txt -F --waf-evasion -b [your-callback-url] --output dalfox.txt
echo "Dalfox scan complete" | notify -silent