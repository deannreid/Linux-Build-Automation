#!/bin/bash
##
 # Linux Build Automation
 # Built by @Dean Reid
 #
 # Class: Linux-MulticraftDeployment.ps1
 #  
 # Class Information:
 #
 # Class checks if software installed is installed then runs the installation for each program noted in install-list
 # 
 # Program Version: 1.0
 # Code Version: 1.0
 # 
 # Updates: 
 # 27/08/2023 - Initial Code Development
 # 27/08/2023 - Fixed the Broke stuff


 ## PLEASE NOTE: This installer assumes that your NIC name is : enp0s31f6
 # If this is not the case you need to change it 
 ###

#####################
##### VARIABLES #####
#####################

# **************** #
# Application List #
# **************** #
PACKAGE_LIST=(
    'build-essential'
    'perl'
    'openjdk-7-jre'
    'libjson-xs-perl'
    'libstdc++6'
    'perl'
    'libnet-ssleay-perl'
    'openssl'
    'libauthen-pam-perl'
    'libpam-runtime'
    'libio-pty-perl'
    'apt-show-versions'
    'python'
    'libhiredis-dev'
    'libdbd-mysql-perl'
    'g++-multilib'
    'lib32stdc++6'
    'screen'
    'redis-server'
    'mysql-client'
    'mysql-server'
    'openssl'
    'clamav'
    'clamav-daemon'
    'unzip'
    'bzip2'
    'apache2'
    'apache2-doc'
    'apache2-utils'
    'libapache2-mod-php5'
    'php5'
    'php5-common'
    'php5-gd'
    'php5-mysql'
    'php5-imap'
    'phpmyadmin'
    'php5-cli'
    'php5-cgi'
    'libapache2-mod-fcgid'
    'apache2-suexec-pristine'
    'php-pear'
    'php-auth'
    'php5-mcrypt'
    'mcrypt'
    'php5-imagick'
    'imagemagick'
    'libruby'
    'libapache2-mod-python'
    'php5-curl'
    'php5-intl'
    'php5-memcache'
    'php5-memcached'
    'php5-ming'
    'php5-ps'
    'php5-pspell'
    'php5-recode'
    'php5-sqlite'
    'php5-tidy'
    'php5-xmlrpc'
    'php5-xsl'
    'memcached'
    'libapache2-mod-fastcgi'
    'php5-fpm'
)


# Define Shell colors...
RED=$(tput bold && tput setaf 1)
GREEN=$(tput bold && tput setaf 2)
YELLOW=$(tput bold && tput setaf 3)
BLUE=$(tput bold && tput setaf 4)
NC=$(tput sgr0)

function RED(){
	echo -e "\n${RED}${1}${NC}"
}
function GREEN(){
	echo -e "\n${GREEN}${1}${NC}"
}
function YELLOW(){
	echo -e "\n${YELLOW}${1}${NC}"
}
function BLUE(){
	echo -e "\n${BLUE}${1}${NC}"
}

#######################
# DO NOT CHANGE BELOW #
#######################

# ***************
# Check Root 
# ***************
if [ $UID -ne 0 ]
then
	RED "You must run this script as root!" && echo
	exit
fi

##
# Check Installed OS
##

OUTPUT=$(cat /etc/*release)

if  echo "$OUTPUT" | grep -q "CentOS Linux 7" ; then
        echo "Checking and installing curl and wget"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
        SERVER_OS="CentOS"
elif echo "$OUTPUT" | grep -q "CentOS Linux 8" ; then
        echo -e "\nDetecting Centos 8...\n"
        SERVER_OS="CentOS8"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
elif echo "$OUTPUT" | grep -q "Ubuntu 18.04" ; then
	apt install -y -qq wget curl
        SERVER_OS="Ubuntu"
elif echo "$OUTPUT" | grep -q "Ubuntu 20.04" ; then
	apt install -y -qq wget curl
        SERVER_OS="Ubuntu20"
elif echo "$OUTPUT" | grep -q "Ubuntu 22.04" ; then
	apt install -y -qq wget curl
	SERVER_OS="Ubuntu22"
else
        echo -e "\nUnable to detect your OS...\n"
        echo -e "\nOnly supported on Ubuntu 18.04, Ubuntu 20.04, Ubuntu 20.10, Ubuntu 22.04,  CentOS 7.x, CentOS 8.x...\n"
        exit 1
fi

# ***************
# Check Compatibility 
# ***************
echo -e "${BLUE}Checking Compatibility ${NC}" ""
if [ -z "$APT_GET_DIR" ]; then
    echo -e "${RED}Compatibility check failed. Cannot find apt-get." "danger ${NC}"
    echo -e "${YELLOW}Exiting" "danger ${NC}"
    exit 1
else
    echo -e "${GREEN}Compatibilty check passed" "success ${NC}"
fi

# Removing unused packages and cache (APT)
echo -e "${RED}Cleaning Unused Packages...${NC}" &&
    sudo apt-get -y autoremove --purge &&
    sudo apt-get clean &&

    # Removing Old Unused Linux Kernels
    IN_USE=$(uname -a | awk '{ print $3 }')
echo -e "${GREEN}Your in use kernel is ${IN_USE} ${NC}"
OLD_KERNELS=$(
    dpkg --list |
        grep -v "$IN_USE" |
        grep -Ei 'linux-image|linux-headers|linux-modules' |
        awk '{ print $2 }'
)
# skipcq: SH-2154
if [ "${#files[@]}" -ne "0" ]; then
    echo -e "\n${GREEN}Old Kernels to be removed:${NC}"
    echo -e "${GREEN}$OLD_KERNELS${NC}\n"
    read -r -p "${RED}Do you want to delete the old kernels? [y/N]${NC} " response
    case "$response" in
    [yY][eE][sS] | [yY])
        for PACKAGE in $OLD_KERNELS; do
            yes | apt purge "$PACKAGE"
        done
        ;;
    *)
        echo -e "${RED}Skipping Removing old kernel...${NC}"
        ;;
    esac
else
    echo -e "${GREEN}No old unused kernel to clean.${NC}"
fi

# Cleaning Thumbnail Cache
echo -e "${RED}Cleaning Thumbnails...${NC}" &&
    sudo rm -rf ~/.cache/thumbnails/* &&

# Delete Boilerplate Directories
BLUE "Removing boilerplate home directories..."
rmdir ~/Desktop ~/Documents ~/Downloads ~/Music ~/Pictures ~/Public ~/Templates ~/Videos

# Delete journal logs older than 5 days
sudo journalctl --vacuum-time=5days

# Summarization
END=$(df /home --output=used | grep -Eo '[0-9]+')
RECLAIMED=$((BEGIN - END))
if [ $RECLAIMED -lt 0 ]; then
    RECLAIMED=0
fi

echo "${GREEN}${RECLAIMED} KB Reclaimed. ${NC}"

# Set a new hostname
echo -e "${GREEN} Hostname Set as:${NC} ${BLUE} ${SET_HOSTNAME} ${NC}"
sudo hostnamectl set-hostname "$SET_HOSTNAME"

# Start Standardised Software Installation
echo -e "${BLUE} Installing Curl ...${NC}"
sudo apt-get install -y curl

## Update Repos and Install
echo -e "${BLUE} Adding Custom and Updating repositories...${NC}"
echo "" | sudo add-apt-repository ppa:webupd8team/java
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
sudo apt update

# *
# Check if installed on VMware
# *
if [[ $(sudo dmidecode -s system-manufacturer) == "VMware, Inc." ]]; then
    sudo apt-get install open-vm-tools -y
fi

# Uncomment if you are setting up a Wazuh SEIM to track baddies
#echo -e "${BLUE} Installing Wazuh...${NC}"
#WAZUH_MANAGER="10.10.10.10" apt install wazuh-agent
#systemctl enable --now wazuh-agent.service

# *
# Install Applications
# *
sudo echo -e "\n${BOLD}${BLUE}Installing Packages${NC}\n"
for pkg in "${PACKAGE_LIST[@]}"; do
    echo "${GREEN}Installing - ${RESET} ${BOLD}$pkg${RESET}"
    sudo apt install "$pkg" -y &> /dev/null
    check_status
done

#* 
# Apache Setup
#*
echo -e "${BLUE} Setting up Apache ...${NC}"
a2enmod suexec rewrite ssl actions include cgi
php5enmod mcrypt
service apache2 restart;
a2enmod actions fastcgi alias;
service apache2 restart;

#* 
# Apache Setup
#*
sudo echo -e "\n${BOLD}${BLUE}Installing Multicraft${NC}\n"
cd ~ || exit
mkdir ./tmp/multicraft
cd ./tmp/multicraft || exit
wget http://www.multicraft.org/download/linux64 -O multicraft.tar.gz
tar xvzf multicraft.tar.gz

sudo echo -e "\n${BOLD}${GREEN}Moving Multicraft Web Panel to /var/www/html${NC}\n"
mv -r ~/tmp/multicraft/multicraft/panel /var/www/html/mcpanel

sudo echo -e "\n${BOLD}${GREEN}Moving Multicraft Daemon to /home/services/multicraft${NC}\n"
mv -r ~/tmp/multicraft/multicraft /home/services/multicraft
cd /home/services/multicraft || exit
./setup.sh

#* 
# Apache Setup
#*
sudo echo -e "\n${BOLD}${GREEN}Visit $IP_ADDRESS$ /mcpanel/install.php to finish installation of the web panel {NC}\n"

# *
# Setup Completed
# *
echo -e "${GREEN} Deployment Setup Complete :) ${NC}"
echo ""
echo -e "The Local IP: $(hostname -I | awk '{print $1}')"
echo -e "The Extrn IP: $(curl -s ifconfig.me)"
echo -e "The gateway IP: $(ip route | awk '/default/ { print $3 }')"
echo -e "The primary DNS IP: $(cat /etc/resolv.conf | grep "nameserver" | awk '{print $2}')"
