#!/bin/bash

lolcat=/usr/games/lolcat
fortune=/usr/games/fortune
#replace subdomain_list for custom subdomain list
subdomain_list=/opt/theoneliner/best-dns-wordlist.txt

get_yes_no() {
    local prompt="$1"
    local answer
    while true; do
        echo -e "$prompt"
        read answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [[ "$answer" == "yes" || "$answer" == "y" ]]; then
            return 0
        elif [[ "$answer" == "no" || "$answer" == "n" || -z "$answer" ]]; then
            return 1
        else
            echo "Invalid input. Please enter yes/y or no/n (or press enter for no)"
        fi
    done
}

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

echo -e "\nPlease answer the following configuration questions:\n"


echo -e "\nPlease mention the file path for waymore.py (Press enter to set it as per install.sh)"
read waymore_file_path
if [[ -z $waymore_file_path ]]; then
	echo -e "\nNo input, path set as per install.sh - /opt/waymore/waymore/waymore.py"
	waymore_file_path="/opt/waymore/waymore/waymore.py"
else
	echo -e "\nWaymore path set successfully!"
fi

echo -e "\nRunning wafw00f"
wafw00f $domain
echo -e "\n\nDo you wish to run a portscan after subdomain enumeration? Recommended not to run a portscan if target is behind a WAF. (yes/y or no/n, default: no)"
if get_yes_no; then
    nuclei_input_file=portscan.txt
    portscan_answer="yes"
    echo -e "\n\nEnter rate limit for portscanning (press enter for default 2000)"
    read portscan_rate
    if [[ ! $portscan_rate =~ ^[0-9]+$ ]]; then
        portscan_rate=2000
        echo -e "\n\nDefault Portscan rate limit value set to 2000"
    fi
else
    nuclei_input_file=resolvedsubs.txt
    portscan_answer=""
fi


echo -e "\n\nDo you wish to use Dalfox (Callback URL Required)? (yes/y or no/n, default: no)"
if get_yes_no; then
    echo -e "Enter your callback URL:"
    read dalfox_callbackurl
    if [[ -z "$dalfox_callbackurl" ]]; then
        echo "Callback URL cannot be empty. Dalfox will be skipped."
        dalfox_callbackurl=""
    fi
else
    dalfox_callbackurl=""
fi


echo -e "\n\nDo you wish to run Nuclei? (yes/y or no/n, default: no)"
if get_yes_no; then
    nuclei_answer="yes"
    echo -e "\n\nEnter rate limit for Nuclei (press enter for default 200):"
    read nuclei_rate
    if [[ ! $nuclei_rate =~ ^[0-9]+$ ]]; then
        nuclei_rate=200
        echo -e "\n\nDefault Nuclei rate limit value set to 200"
    fi
else
    nuclei_answer=""
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
#value=$(curl -s https://ftp.ripe.net/ripe/asnames/asn.txt)

# Saving ASNs and IP ranges in vars
asn=$(curl -s https://ftp.ripe.net/ripe/asnames/asn.txt | grep -i "\<$org\>" | awk '{print "AS"$1}' | paste -sd,)
ipranges=""

if [[ -z $asn && -z $ipranges ]]
then
    echo -e "No ASNs and Subnets found. Do you want to add both manually? (yes/y or no/n, default: no)"
    if get_yes_no; then
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
    echo -e "No ASNs found. Do you want to add ASNs manually? (yes/y or no/n, default: no)"
    if get_yes_no; then
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
    echo -e "No Subnets found. Do you want to add Subnets manually? (yes/y or no/n, default: no)"
    if get_yes_no; then
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

echo -e "Do you want to run DNSValiator? Takes a while to run. (Default - Trickest Resolvers) (yes/y or no/n, default: no)"
if get_yes_no; then
    #dnsvalidator
	printf '\nCollecting DNS resolvers using DNSValidator\n' | pv -qL 150 | $lolcat
	sleep 5
 	dnsvalidator --silent -tL https://public-dns.info/nameservers.txt -threads 50 | tee resolvers.txt
 	sort -R resolvers.txt | tail -n 150 > 100resolvers.txt
 	rm resolvers.txt
 	mv 100resolvers.txt ../100resolvers.txt
	resolver_file_path="../100resolvers.txt"
	echo -e "DNS Resolvers collected, initating enumeration and scanning" | notify -silent
else
    echo -e "Setting Resolver file to the default"
    wget https://raw.githubusercontent.com/trickest/resolvers/refs/heads/main/resolvers.txt
    mv resolvers.txt ../
	resolver_file_path="../resolvers.txt"
fi

#amass
sleep 2
printf '\nRunning Amass Intel\n' | pv -qL 50 | $lolcat
sleep 5
touch amassintel.txt
if [[ ! -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -cidr $ipranges -timeout 5000 -rf $resolver_file_path -o amassintel.txt
elif [[ ! -z $asn && -z $ipranges ]]
then
	amass intel -active -whois -d $domain -asn $asn -timeout 5000 -rf $resolver_file_path -o amassintel.txt
elif [[ -z $asn && ! -z $ipranges ]]
then
	amass intel -active -whois -d $domain -cidr $ipranges -timeout 5000 -rf $resolver_file_path -o amassintel.txt
else
	amass intel -active -whois -d $domain -timeout 5000 -rf $resolver_file_path -o amassintel.txt
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
	amass enum -active -d $domain -nf subdomains.txt -rf $resolver_file_path -timeout 5000 -nocolor  -o amassenum.txt
else
	amass enum -active -d $domain -rf $resolver_file_path -timeout 5000 -nocolor -o amassenum.txt
fi

#filter results from amass enum file 
cat amassenum.txt | cut -d " " -f 1 | grep -i $domain | tee amassenum-1.txt
cat amassenum-1.txt | grep $domain | anew subdomains.txt
rm amassenum.txt
rm amassenum-1.txt

#Running subfinder
sleep 2
printf '\nRunning Subfinder\n' | pv -qL 50 | $lolcat
sleep 5
touch subfinder.txt
subfinder -d $domain -all -o subfinder.txt -pc ~/.config/subfinder/provider-config.yaml -rL $resolver_file_path -nc

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

#integrating ip.thc.org
sleep 2
printf '\nQuerying ip.thc.org\n' | pv -qL 50 | $lolcat
sleep 5
touch thc-ipranges.txt
touch thc-subdomain.txt

# Feature 1: IP ranges (only if $ipranges is set)
if [[ -n "$ipranges" ]]; then
    # Validate IP format (basic check)
    if [[ ! "$ipranges" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/(8|16|24)$ ]]; then
        echo "Error: Invalid IP range format. Must be valid IP with /8, /16, or /24"
    else
        # Validate IP octets are <= 255
        valid_ip=true
        IFS='.' read -ra OCTETS <<< "${ipranges%%/*}"
        for octet in "${OCTETS[@]}"; do
            if [[ $octet -gt 255 ]]; then
                valid_ip=false
                break
            fi
        done
        
        if [[ "$valid_ip" == false ]]; then
            echo "Error: Invalid IP address (octets must be 0-255)"
        else
            # Fetch data with timeout
            http_code=$(curl -s -w "%{http_code}" -o /tmp/thc_ip_response.txt \
                --connect-timeout 10 --max-time 30 \
                -L "https://ip.thc.org/api/v1/download?ip_address=$(echo "$ipranges" | sed 's/\//%2F/g')" \
                -H 'Accept: text/csv')
            
            response=$(cat /tmp/thc_ip_response.txt)
            rm -f /tmp/thc_ip_response.txt
            
            # Check HTTP status code
            if [[ "$http_code" != "200" ]]; then
                echo "Error: API returned HTTP $http_code for IP range"
            elif [[ -z "$response" ]] || [[ "$response" == *"\"status\": \"error\""* ]] || [[ $(echo "$response" | wc -l) -le 1 ]]; then
                echo "Error: Failed to fetch IP range data or no results found"
            else
                # Save first column (skip header)
                echo "$response" | tail -n +2 | cut -d',' -f1 > thc-ipranges.txt
                echo "Success: Saved IP range data to thc-ipranges.txt"
            fi
        fi
    fi
fi

# Feature 2: Subdomains (always runs)
if [[ -z "$domain" ]]; then
    echo "Error: domain variable is empty"
else
    # Sanitize domain (remove spaces, special chars except dots and hyphens)
    domain=$(echo "$domain" | tr -cd '[:alnum:].-' | tr -s '.')
    
    if [[ -z "$domain" ]] || [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$ ]]; then
        echo "Error: Invalid domain format after sanitization"
    else
        # Fetch data with timeout
        http_code=$(curl -s -w "%{http_code}" -o /tmp/thc_subdomain_response.txt \
            --connect-timeout 10 --max-time 30 \
            -L "https://ip.thc.org/api/v1/subdomains/download?domain=${domain}" \
            -H 'Accept: text/csv')
        
        response=$(cat /tmp/thc_subdomain_response.txt)
        rm -f /tmp/thc_subdomain_response.txt
        
        # Check HTTP status code
        if [[ "$http_code" != "200" ]]; then
            echo "Error: API returned HTTP $http_code for subdomains"
        elif [[ -z "$response" ]]; then
            echo "Error: Failed to fetch subdomain data"
        else
            # Save without header
            echo "$response" | tail -n +2 > thc-subdomain.txt
            
            # Check if file is empty or only whitespace
            if [[ ! -s thc-subdomain.txt ]] || [[ $(grep -c . thc-subdomain.txt) -eq 0 ]]; then
                echo "Warning: No subdomains found for domain $domain"
            else
                echo "Success: Saved subdomain data to thc-subdomain.txt"
            fi
        fi
    fi
fi

cat thc-subdomain.txt | grep $domain | anew subdomains.txt
cat thc-ipranges.txt | grep $domain | anew subdomains.txt
# not removing the following for now to check how good ip.thc.org is
#rm thc-ipranges.txt
#rm thc-subdomain.txt

#Running puredns
sleep 2
printf '\nRunning PureDNS\n' | pv -qL 50 | $lolcat
sleep 5
touch puredns.txt
puredns bruteforce $subdomain_list $domain --resolvers $resolver_file_path | tee puredns.txt
cat puredns.txt | grep $domain | anew subdomains.txt

# ldns-walk, needs some work, need to account for NSEC3 records
#ldns-walk $domain | tee ldns-subdomains.txt
#cat ldns-subdomains.txt | grep $domain | cut -d " " -f 1 | sed 's/\.$//' | sort | uniq | anew subdomains.txt

### Improving DNS wordlist
cat subdomains.txt | cut -d '.' -f 1 | anew ../best-dns-wordlist.txt

#Running httpx
sleep 2
printf '\nFiltering valid domains using HTTPX\n' | pv -qL 50 | $lolcat
sleep 5
touch resolvedsubs.txt
httpx -l subdomains.txt -silent -rl 1 -timeout 15 -o resolvedsubs.txt

#filtering httpx output to remove http(s)://, requires moreutils, apt-get install moreutils
cat resolvedsubs.txt | cut -d "/" -f 3 | sponge resolvedsubs.txt
echo -e "Subdomain enumeration for "$domain" has been completed\n" | notify -silent
echo -e "Total subdomains: $(cat subdomains.txt | wc -l) & Resolved subdomains: $(cat resolvedsubs.txt | wc -l)\n" | notify -silent


#integrating gau, waymore, waybackurls and katana
touch spidering.txt
touch tempfile.txt
#Running gau
sleep 2
printf '\nCollecting URLs using GAU\n' | pv -qL 50 | $lolcat
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

#Running hakrawler
sleep 2
printf '\nSpidering using Hakrawler\n' | pv -qL 50 | $lolcat
sleep 5
echo "https://$domain" | hakrawler -subs | tee tempfile.txt 
cat tempfile.txt | anew spidering.txt

#Running waybackurls
sleep 2
printf '\nCollecting URLs using waybackurls\n' | pv -qL 50 | $lolcat
sleep 5
cat subdomains.txt | waybackurls > tempfile.txt
cat tempfile.txt | anew spidering.txt

#sleep 2
#printf '\nSpidering using GoSpider\n' | pv -qL 50 | $lolcat
#sleep 5
#gospider -S subdomains.txt --js --subs --sitemap -a -w -r | tee tempfile.txt
#cat tempfile.txt | anew spidering.txt

rm tempfile.txt

#removing duplicate entries
cat spidering.txt | sort -u | uniq | sponge spidering.txt
echo -e "Spidering for "$domain" has been completed, total links found: $(cat spidering.txt | wc -l)\n" | notify -silent

#JS scanning for endpoints and screts
cat spidering.txt | grep "\.js$" | tee js.txt
cat js.txt | jsluice secrets | jq | tee jsluice-secrets.txt
cat js.txt | jsluice urls | jq | tee jsluice-api-endpoints.txt

if [[ -n $portscan_answer ]]; then
	#portscanning
	sleep 2
	printf '\nPort scanning using Naabu\n' | pv -qL 50 | $lolcat
	sleep 5
	naabu -l subdomains.txt -p 1-65535 -rate $portscan_rate -timeout 5000 | tee portscan.txt
	echo -e "Portscanning for "$domain" has been completed\n" | notify -silent
else
	echo -e "\nPort Scanning Skipped, Nuclei will run on resolved subdomains"
fi

#Running nuclei
if [[ -n $nuclei_answer ]]; then
	#portscanning
    sleep 2
    printf '\nVulnerability scanning using Nuclei\n' | pv -qL 50 | $lolcat
    sleep 5
    nuclei -l $nuclei_input_file -rl $nuclei_rate -t ~/nuclei-templates/ | tee nuclei.txt
    nucleilow=$(cat nuclei.txt | grep '32mlow' | wc -l)
    nucleimedium=$(cat nuclei.txt | grep '33mmedium' | wc -l)
    nucleihigh=$(cat nuclei.txt | grep '208mhigh' | wc -l)
    echo "Nuclei scan results: High: "$nucleihigh"  Medium: "$nucleimedium"  Low: "$nucleilow"" | notify -silent
else
    echo -e "\nNuclei Skipped"
fi

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
    rm resolvedsubswithprotocol.txt
else
	echo -e "\nDalfox skipped"
fi