##
 # Linux Build Automation
 # Built by @Dean Reid
 #
 # Class: LinuxInstaller.ps1
 #  
 # Class Information:
 #
 # Class checks if the software installed is installed then run the installation for each program noted in Package List
 # 
 # Program Version: 1.0
 # Code Version: 1.0
 # 
 # Updates: 
 # 15/03/2023 - Initial Code Development
 # 19/08/2023 - Added Basic Networking Setup
 # 19/08/2023 - Added OS Detection
 ###

#!/bin/bash

#####################
##### VARIABLES #####
#####################

multiphp_v=("7.2" "7.3" "7.4" "8.0" "8.1" "8.2")
fpm_v="8.2"
mariadb_v="10.11"

# **************** #
# Application List #
# **************** #
PACKAGE_LIST=(
    'git'
    'python3-dev'
    'python3-distlib'
    'python3-filelock'
    'python3-pip'
    'python3-pip-whl'
    'python3-virtualenv'
    'nodejs'
    'apache2'
    'apache-suexec-custom'
    'apache2.2-common'
    'apache2-utils'
    'libapache2-mod-fcgid' 
    'libapache2-mod-php$fpm_v' 
    'libapache2-mod-rpaf'
    'php$fpm_v' 
    'php$fpm_v-apcu' 
    'php$fpm_v-bz2' 
    'php$fpm_v-cgi' 
    'php$fpm_v-cli' 
    'php$fpm_v-common' 
    'php$fpm_v-curl' 
    'php$fpm_v-gd'
    'php$fpm_v-imagick' 
    'php$fpm_v-imap' 
    'php$fpm_v-intl' 
    'php$fpm_v-ldap' 
    'php$fpm_v-mbstring' 
    'php$fpm_v-mysql' 
    'php$fpm_v-opcache'
    'php$fpm_v-pgsql' 
    'php$fpm_v-pspell' 
    'php$fpm_v-readline' 
    'php$fpm_v-xml' 
    'php$fpm_v-zip'
    'sqlite3'
    )


# Define Shell colors...
RED=`tput bold && tput setaf 1`
GREEN=`tput bold && tput setaf 2`
YELLOW=`tput bold && tput setaf 3`
BLUE=`tput bold && tput setaf 4`
NC=`tput sgr0`

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

if  echo $OUTPUT | grep -q "CentOS Linux 7" ; then
        echo "Checking and installing curl and wget"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
        SERVER_OS="CentOS"
elif echo $OUTPUT | grep -q "CentOS Linux 8" ; then
        echo -e "\nDetecting Centos 8...\n"
        SERVER_OS="CentOS8"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
elif echo $OUTPUT | grep -q "CloudLinux 7" ; then
        echo "Checking and installing curl and wget"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
        SERVER_OS="CloudLinux"
elif echo $OUTPUT | grep -q "AlmaLinux 8" ; then
	echo "Checking and installing curl and wget"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
        SERVER_OS="AlmaLinux"
elif echo $OUTPUT | grep -q "Rocky Linux" ; then 
	echo "Checking and installing curl and wget"
	yum install curl wget -y 1> /dev/null
	yum update curl wget ca-certificates -y 1> /dev/null
	SERVER_OS="RockyLinux"
elif echo $OUTPUT | grep -q "Ubuntu 18.04" ; then
	apt install -y -qq wget curl
        SERVER_OS="Ubuntu"
elif echo $OUTPUT | grep -q "Ubuntu 20.04" ; then
	apt install -y -qq wget curl
        SERVER_OS="Ubuntu20"
elif echo $OUTPUT | grep -q "Ubuntu 22.04" ; then
	apt install -y -qq wget curl
	SERVER_OS="Ubuntu22"
else
        echo -e "\nUnable to detect your OS...\n"
        echo -e "\nScript is supported on Ubuntu 18.04, Ubuntu 20.04, Ubuntu 20.10, Ubuntu 22.04,  CentOS 7.x, CentOS 8.x,  CloudLinux 7.x, CloudLinux 8.x and AlmaLinux 8.x...\n"
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
echo ""
echo -e "${GREEN} Deployment Setup ${NC}"
echo ""

# Start Standardised Software Installation
echo -e "${BLUE} Installing Curl ...${NC}"
sudo apt-get install -y curl

# *
# Check if installed on VMware
# *
if [[ $(sudo dmidecode -s system-manufacturer) == "VMware, Inc." ]]; then
    sudo apt-get install open-vm-tools -y
fi

# Wazuh Installation
# Not Reqd
# echo -e "${BLUE} Installing Wazuh...${NC}"
# WAZUH_MANAGER="10.0.14.54" apt install wazuh-agent
# systemctl enable --now wazuh-agent.service

# *
# Install Applications
# *
sudo echo -e "\n${BOLD}${BLUE}Installing Packages${NC}\n"
for pkg in "${PACKAGE_LIST[@]}"; do
    echo "${GREEN}Installing - ${RESET} ${BOLD}$pkg${RESET}"
    sudo apt install "$pkg" -y &> /dev/null
    check_status
done

sudo echo -e "\n${BOLD}${GREEN}Packages$ Installed{NC}\n"
sudo echo -e "\n${BOLD}${BLUE}Web Server File Location: /var/www${NC}\n"
sudo echo -e ""
sudo echo -e "\n${BOLD}${BLUE}Server running at http://localhost/${NC}\n"