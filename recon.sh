#!/bin/bash

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
printf '\n\n'
echo "Enter organisation name: "
read org
printf '\n'

echo -e "\nPlease mention the file path for waymore.py (Press enter to set it as per install.sh)"
read waymore_file_path
if [[ -z $waymore_file_path ]]; then
	echo -e "\nNo input, path set as per install.sh - /opt/waymore/waymore/waymore.py"
	waymore_file_path="/opt/waymore/waymore/waymore.py"
else
	echo -e "\nWaymore path set successfully!"
fi

echo -e "\n\nDo you wish to use Dalfox? Enter your callback URL if yes (Press enter if no)"
read dalfox_callbackurl

echo -e "\n\nDo you wish to run a portscan after subdomain enumeration? Recommended not to run a portscan if target is behind a WAF. (Press enter if no)"
read portscan_answer
if [[ $portscan_answer ]]; then
	nuclei_input_file=portscan.txt
else
	nuclei_input_file=resolvedsubs.txt
fi

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

# Function to validate comma-separated input
validate_comma_separated() {
    local input="$1"
    local validate="^([0-9a-zA-Z./]+,)*[0-9a-zA-Z./]+$"
    [[ "$input" =~ $validate ]]
}

# Fetching all ASNs
value=$(curl -s https://ftp.ripe.net/ripe/asnames/asn.txt)

# Saving ASNs and IP ranges in vars
asn=$(echo "$value" | grep -i "\<$org\>" | awk '{print "AS"$1}' | paste -sd,)
ipranges=""

if [[ -z $asn && -z $ipranges ]]
then
    echo -e "No ASNs and Subnets found. Do you want to add both manually? (press enter if no)"
    read answer
    if [[ -n $answer ]]
    then
        while true; do
            echo -e "You can visit bgp.he.net for the values"
            echo -e "Enter ASNs (Comma-separated):"
            read asn
            if validate_comma_separated "$asn"; then
                break
            else
                echo "Invalid input. Please enter comma-separated values."
            fi
        done

        while true; do
            echo -e "Enter Subnets (Comma-separated):"
            read ipranges
            if validate_comma_separated "$ipranges"; then
                break
            else
                echo "Invalid input. Please enter comma-separated values."
            fi
        done
    else
        echo -e "No ASNs and Subnets were added."
    fi
elif [[ -z $asn && -n $ipranges ]]
then
    echo -e "No ASNs found. Do you want to add ASNs manually? (press enter if no)"
    read answer
    if [[ -n $answer ]]
    then
        while true; do
            echo -e "You can visit bgp.he.net for the values"
            echo -e "Enter ASNs (Comma-separated):"
            read asn
            if validate_comma_separated "$asn"; then
                break
            else
                echo "Invalid input. Please enter comma-separated values."
            fi
        done
    else
        echo -e "No ASNs were added."
    fi
elif [[ -n $asn && -z $ipranges ]]
then
    echo -e "No Subnets found. Do you want to add Subnets manually? (press enter if no)"
    read answer
    if [[ -n $answer ]]
    then
        while true; do
            echo -e "You can visit bgp.he.net for the values"
            echo -e "Enter Subnets (Comma-separated):"
            read ipranges
            if validate_comma_separated "$ipranges"; then
                break
            else
                echo "Invalid input. Please enter comma-separated values."
            fi
        done
    else
        echo -e "No Subnets were added."
    fi
else
    echo -e "ASNs and Subnets are already provided."
fi

echo -e "ASNs: "$asn"\n"
echo -e "IP/ranges: "$ipranges"\n"

echo -e "Do you want to run DNSValiator? can take a while to run. (press enter if no)"
read answer
if [[ $answer ]]; then
    #dnsvalidator
	printf '\nCollecting DNS resolvers using DNSValidator\n' | pv -qL 50 | $lolcat
	sleep 5
	dnsvalidator --silent -tL https://public-dns.info/nameservers.txt -threads 50 | tee resolvers.txt
	sort -R resolvers.txt | tail -n 150 > 100resolvers.txt
	rm resolvers.txt
	mv 100resolvers.txt ../100resolvers.txt
	resolver_file_path="../100resolvers.txt"
	echo -e "DNS Resolvers collected, initating enumeration and scanning" | notify -silent
else
    echo -e "Setting Resolver file to the default"
	resolver_file_path="../resolvers.txt"
fi

#amass
sleep 2
printf '\nRunning Amass Intel\n' | pv -qL 50 | $lolcat
sleep 5
touch amassintel.txt
if [[ ! -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -cidr $ipranges -timeout 500 -rf $resolver_file_path -o amassintel.txt
elif [[ ! -z $asn && -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -timeout 500 -rf $resolver_file_path -o amassintel.txt
elif [[ -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -cidr $ipranges -timeout 500 -rf $resolver_file_path -o amassintel.txt
else
	amass intel -active -whois -d $domain -timeout 500 -rf $resolver_file_path -o amassintel.txt
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
#	amass enum -active -d $domain -nf subdomains.txt -rf $resolver_file_path -timeout 100 -nocolor -o amassenum.txt
#else
#	amass enum -active -d $domain -rf $resolver_file_path -timeout 100 -nocolor -o amassenum.txt
#fi

#filter results from amass enum file 
#cat amassenum.txt | grep $domain | anew subdomains.txt
#rm amassenum.txt

#Running subfinder
sleep 2
printf '\nRunning Subfinder\n' | pv -qL 50 | $lolcat
sleep 5
touch subfinder.txt
subfinder -dL subdomains.txt -all -o subfinder.txt -pc ~/.config/subfinder/provider-config.yaml -rL $resolver_file_path -nc

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

#issues with katana, need to check
#Running Katana
#sleep 2
#printf '\nSpidering using Katana\n' | pv -qL 50 | $lolcat
#sleep 5
#katana -list subdomains.txt -d 4 -jc -rl 50 | tee tempfile.txt
#cat tempfile.txt | anew spidering.txt

#Running Waymore
sleep 2
printf '\nSpidering using Waymore\n' | pv -qL 50 | $lolcat
sleep 5
python3 $waymore_file_path -i $domain -mode U | tee tempfile.txt 
cat tempfile.txt | anew spidering.txt

Running waybackurls
sleep 2
printf '\Collecting URLs using waybackurls\n' | pv -qL 50 | $lolcat
sleep 5
cat subdomains.txt | waybackurls > tempfile.txt
cat tempfile.txt | anew spidering.txt

#sleep 2
#printf '\nSpidering using GoSpider\n' | pv -qL 50 | $lolcat
#sleep 5
#gospider -S subdomains.txt --js --subs --sitemap -a -w -r | tee tempfile.txt
#cat tempfile.txt | anew spidering.txt
#rm tempfile.txt

#removing duplicate entries
cat spidering.txt | sort -u | uniq | sponge spidering.txt
echo -e "Spidering for "$domain" has been completed, total links found: $(cat spidering.txt | wc -l)\n" | notify -silent

if [[ -n $portscan_answer ]]; then
	#portscanning
	sleep 2
	printf '\nPort scanning using Naabu\n' | pv -qL 50 | $lolcat
	sleep 5
	naabu -l subdomains.txt -p 1-65535 -rate 2000 -timeout 5000 | tee portscan.txt
	echo -e "Portscanning for "$domain" has been completed\n" | notify -silent
else
	echo -e "\nPort Scanning Skipped, Nuclei will run on resolved subdomains"
fi

#Running nuclei
sleep 2
printf '\nVulnerability scanning using Nuclei\n' | pv -qL 50 | $lolcat
sleep 5
nuclei -l $nuclei_input_file -rl 1000 -t ~/nuclei-templates/ | tee nuclei.txt
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
if [[ -n $dalfox_callbackurl ]]; then
	sleep 2
	printf '\nRunning Dalfox\n' | pv -qL 50 | $lolcat
	sleep 5
	dalfox file resolvedsubswithprotocol.txt --mining-dict-word params.txt -F --waf-evasion -b 	$dalfox_callbackurl --output dalfox.txt
	echo "Dalfox scan complete" | notify -silent
else
	echo -e "\nDalfox skipped"
fi