# THEONELINER

Recon that could've been done with a one liner but why not make a 200 line script :)

# Description
A basic recon script for subdomain enumeration, spidering, port scanning and nuclei, the script consists of the following tools:
```text
DnsValidator
Amass
Subfinder
Assetfinder
Httpx
Gau
Waymore
Katana
Gospider
Naabu
Nuclei
Dalfox
```

It is recommended to run this on a VPS as I had designed this with ease of setup on new VPS instances in mind.


# Installation

```bash
git clone https://github.com/kxddah/theoneliner.git
cd theoneliner
```

The `install.sh` would install everything mentioned in the tool section above along with setting up [Golang](https://go.dev/doc/install).
```bash
./install.sh
```
Note: I've noticed the golang config does not persist on reboot, but since I don't reboot my VPS I don't usually face any issues.

# Configuration
You would have to configure the config files for [Amass](https://github.com/owasp-amass/amass/blob/master/doc/user_guide.md#the-configuration-file) and [Subfinder](https://github.com/projectdiscovery/subfinder/blob/master/README.md#post-installation-instructions) if you'd like to have api-keys, just follow the respective guides to setup those, add them in the root folder `~/.config/amass/datasources.yaml` and `~/.config/subfinder/provider-config.yaml`

New addition to the script is [Notify](https://github.com/projectdiscovery/notify#provider-config), setup the config file at  `~/.config/notify/provider-config.yaml`

Another addition to the script is Dalfox: Don't forget to change the [your-callback-url] for the dalfox command, this should include your call back URL, if you don't have one then remove `-b [your-callback-url]`

I'll make improvements as I understand the tool better, maybe include more tools like so



# Running theoneliner
- Run the recon script
```bash
./recon.sh
```

- The script would collect DNS resolvers using DnsValidator, then collect subdomains from Amass, Subfinder and Assetfinder. It'll run it through httpx to see which ones resolve.
- Further it will use gau, waymore and katana to find different links and files by spidering and quering 3rd parties.
- Then it'll run a port scan on the list of unresolved subdomains, this is because the the unresolved subdomain might not be running something on port 443 or 80, but might have different ports open
- At last it'll put the portscan result into nuceli for vulnerability scanning
- During all this you could configure Notify to send notifications to discord, slack, etc. This script sends notification on completion of collection of DNS resolvers, subdomain enumeration, spidering, port scan and nuclei scan.


# Future improvements:
- Add support for multiple domains, currenlty the tool takes only one domain and runs the scanning.
