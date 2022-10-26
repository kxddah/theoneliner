# THEONELINER

Recon that could've been done with a one liner but why not make a 100 line script :)

# Description
A basic recon script for subdomain enumeration that combines the following tools:
```text
DnsValidator
Amass
Subfinder
Assetfinder
Httpx
```

I usually run this on my VPS, didn't make it with convenience in mind, it just gets the work done


# Installation

```bash
git clone https://github.com/kxddah/theoneliner.git
cd theoneliner
```

The `basicDependency.sh` contains the basic dependency
```bash
./basicDependency.sh
```

The `dependency.sh` would install everything like [Golang](https://go.dev/doc/install), [anew](https://github.com/tomnomnom/anew#install), [DnsValidator](https://github.com/vortexau/dnsvalidator#setup), [Amass](https://github.com/OWASP/Amass#installation----), [Subfinder](https://github.com/projectdiscovery/subfinder/blob/master/README.md#installation), [Assetfinder](https://github.com/tomnomnom/assetfinder#assetfinder) and [httpx](https://github.com/projectdiscovery/httpx#installation-instructions). If you have golang or any other tools installed just comment that part out or manually install the other tools.
```bash
./dependency.sh
```
You would have to configure the config files for [Amass](https://github.com/OWASP/Amass/blob/master/examples/config.ini) and [Subfinder](https://github.com/projectdiscovery/subfinder/blob/master/README.md#post-installation-instructions) if you'd like to have api-keys, just follow the respective guides to setup those, add them in the root folder `~/.config/amass/config.ini` and `~/.config/subfinder/provider-config.yaml`


# Running theoneliner
- Go to [bgp.he.net](https://bgp.he.net/) and search for the company you're doing recon on, copy the results and paste it in a `bgp.txt` file
- Run the recon script
```bash
./recon.sh
```
- The script would collect DNS resolvers using DnsValidator, then collect results from Amass, Subfinder and Assetfinder. Then it would run it through httpx to see which ones resolve and voila we have a list of subdomains

https://user-images.githubusercontent.com/94586114/198102425-d1fbccff-c791-4724-81d2-57414183074a.mp4
