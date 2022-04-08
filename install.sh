#!/usr/bin/env bash

## Global variables ##

# Variables used for toggling verbose mode
VERBOSE=0
SILENT="-s"

# Variables used for setting color of text in echo
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[1;33m"
ENDCOL="\e[0m"

# Variables used for determining Linux distro
RHEL="Red Hat Enterprise Linux"
CENTOS="CentOS Linux"
FEDORA="Fedora Linux"
UBUNTU="Ubuntu"
DEBIAN="Debian GNU/Linux 11 (bullseye)"


## Functions ##

# MOTD

motd ()
{
    echo ""
    echo -e "${YELLOW}"
    echo '$$$$$$\                       $$\               $$\ $$\ '
    echo '\_$$  _|                      $$ |              $$ |$$ |'
    echo '  $$ |  $$$$$$$\   $$$$$$$\ $$$$$$\    $$$$$$\  $$ |$$ |'
    echo '  $$ |  $$  __$$\ $$  _____|\_$$  _|   \____$$\ $$ |$$ |'
    echo '  $$ |  $$ |  $$ |\$$$$$$\    $$ |     $$$$$$$ |$$ |$$ |'
    echo '  $$ |  $$ |  $$ | \____$$\   $$ |$$\ $$  __$$ |$$ |$$ |'
    echo '$$$$$$\ $$ |  $$ |$$$$$$$  |  \$$$$  |\$$$$$$$ |$$ |$$ |'
    echo '\______|\__|  \__|\_______/    \____/  \_______|\__|\__|'
    echo ""
    echo ' $$$$$$\                      $$\             $$\     '
    echo '$$  __$$\                     \__|            $$ |    '
    echo '$$ /  \__| $$$$$$$\  $$$$$$\  $$\  $$$$$$\  $$$$$$\   '
    echo '\$$$$$$\  $$  _____|$$  __$$\ $$ |$$  __$$\ \_$$  _|  '
    echo ' \____$$\ $$ /      $$ |  \__|$$ |$$ /  $$ |  $$ |    '
    echo '$$\   $$ |$$ |      $$ |      $$ |$$ |  $$ |  $$ |$$\ '
    echo '\$$$$$$  |\$$$$$$$\ $$ |      $$ |$$$$$$$  |  \$$$$  |'
    echo ' \______/  \_______|\__|      \__|$$  ____/    \____/ '
    echo '                                  $$ |                '
    echo '                                  $$ |                '
    echo '                                  \__|                '
    echo -e "${ENDCOL}"
    echo ""
}


# Function that checks installed distro and which package manager to use
check_pm ()
{
    # Detects distro name from the os-release file
    DISTRO=$(head -n 1 /etc/os-release | cut -d '"' -f 2)

    # Creates the $SHORT_DISTRO variable for choosing the right GPG key and apt repository during Docker install for Ubuntu and Debian
    if [[ "$DISTRO" == "$UBUNTU" ]]; then
        SHORT_DISTRO="ubuntu"
    elif [[ "$DISTRO" == "$DEBIAN" ]]; then
        SHORT_DISTRO="debian"
    fi

    # Detect which package manager is installeiiiiiiiiAAd
    if [[ $(command -v apt-get) || $(command -v apt) ]]; then
        PM="apt-get"
    elif [[ $(command -v pacman) ]]; then
        PM="pacman"
    elif [[ $(command -v dnf) ]]; then
        PM="dnf"
    elif [[ $(command -v yum) ]]; then 
        PM="yum"
    else
        echo -e "${RED}A package manager could not be detected${ENDCOL}"
        exit 1
    fi
}


# Function for installing Docker Engine
install_docker ()
{
    if [[ "$PM" == "apt-get" ]]; then
        # Removes potentially existing old Docker packages
        echo -e "${BLUE}Removing old Docker packages...${ENDCOL}"
        apt-get remove docker docker-engine docker.io containerd runc

        # Update package lists and install dependencies for GPG-key validation
        apt-get update
        echo -e "${BLUE}Installing dependencies for GPG-key validation...${ENDCOL}"
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Downloads Ubuntu/Debian GPG key for verification of docker packages
        echo -e "${BLUE}Downloading Docker GPG key...${ENDCOL}"
        curl -fSL $SILENT https://download.docker.com/linux/${SHORT_DISTRO}/gpg | gpg \
            --dearmor \
            > /usr/share/keyrings/docker-archive-keyring.gpg

        # Adds the Ubuntu/Debian repository to the apt sources list
        echo -e "${BLUE}Downloading Docker GPG key...${ENDCOL}"
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${SHORT_DISTRO} \
            $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Updates package list and downloads the required Docker packages
        apt-get update
        echo -e "${BLUE}Installing Docker packages...${ENDCOL}"
        apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends

    elif [[ $PM == "dnf" || $PM == "yum" ]]; then
        if [[ "$DISTRO" == "$RHEL" ]]; then
            # Removes old Docker packages
            echo -e "${BLUE}Removing old Docker packages...${ENDCOL}"
            yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine \
                podman \
                runc

            # Installs dependencies for adding new repositories to yum and adds the docker repo
            echo -e "${BLUE}Installing yum-utils...${ENDCOL}"
            yum install -y yum-utils
            echo -e "${BLUE}Adding Docker repository...${ENDCOL}"
            yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/rhel/docker-ce.repo
            
            # Installs Docker packages
            echo -e "${BLUE}Installing Docker packages...${ENDCOL}"
            yum install -y docker-ce docker-ce-cli containerd.io

        elif [[ "$DISTRO" == "$CENTOS" ]]; then
            # Removes old Docker packages
            echo -e "${BLUE}Removing old Docker packages...${ENDCOL}"
            yum remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine

            # Installs required package for adding new repositories to yum and adds the Docker repo
            echo -e "${BLUE}Installing yum-utils...${ENDCOL}"
            yum install -y yum-utils
            echo -e "${BLUE}Adding Docker repository...${ENDCOL}"
            yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/centos/docker-ce.repo
            
            # Installs Docker packages
            echo -e "${BLUE}Installing Docker packages...${ENDCOL}"
            yum install -y docker-ce docker-ce-cli containerd.io
        
        elif [[ "$DISTRO" == "$FEDORA" ]]; then
            # Removes old Docker packages
            echo -e "${BLUE}Removing old Docker packages...${ENDCOL}"
            dnf remove -y docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-selinux \
                docker-engine-selinux \
                docker-engine

            # Installs required package for adding new repositories to dnf and adds the Docker repo
            echo -e "${BLUE}Downloading dnf-plugins-core...${ENDCOL}"
            dnf -y install dnf-plugins-core
            echo -e "${BLUE}Adding Docker repository...${ENDCOL}"
            dnf config-manager \
                --add-repo \
                https://download.docker.com/linux/fedora/docker-ce.repo

            # Installs the Docker packages
            echo -e "${BLUE}Installing Docker packages...${ENDCOL}"
            dnf install -y docker-ce docker-ce-cli containerd.io
        fi
    elif [[ "$PM" == "pacman" ]]; then
        # Arch wiki says this is the way
        # https://wiki.archlinux.org/title/docker#Installation

        # Installs the docker package
        echo -e "${BLUE}Installing Docker package...${ENDCOL}"
        pacman -Sy --noconfirm docker
    fi
}


# Function for installing Docker Compose v1
install_compose_v1 ()
{
    # Downloads the docker-compose binary to the /usr/local/bin/ folder
    echo -e "${BLUE}Downloading docker-compose binary...${ENDCOL}"
    curl \
        -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose \
        $SILENT
    
    # Makes the docker-compose file executable
    chmod +x /usr/local/bin/docker-compose
}


# Function for installing Docker Compose v2
install_compose_v2 ()
{
    NEW_COMPOSE_VER=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')

    # Install Compose v2 for root user
    # Creates the cli-plugins folder for Docker
    mkdir -p ~/.docker/cli-plugins

    curl \
        -SL https://github.com/docker/compose/releases/download/"${NEW_COMPOSE_VER}"/docker-compose-linux-x86_64 \
        -o ~/.docker/cli-plugins/docker-compose \
        $SILENT
    
    chmod +x ~/.docker/cli-plugins/docker-compose

    # Install Compose v2 for all users given as argument
    for user in $USERS; do
        if id -u "$user" &>/dev/null; then
            # Creates the cli-plugins folder for Docker
            mkdir -p /home/"$user"/.docker/cli-plugins/
            # Downloads the docker compose plugin
            echo -e "${BLUE}Downloading Docker Compose plugin for ${ENDCOL}${YELLOW}$user${ENDCOL}${BLUE}...${ENDCOL}"

            curl \
                -SL https://github.com/docker/compose/releases/download/"${NEW_COMPOSE_VER}"/docker-compose-linux-x86_64 \
                -o /home/"$user"/.docker/cli-plugins/docker-compose \
                $SILENT
            
            # Makes the docker compose plugin executable
            chmod +x /home/"$user"/.docker/cli-plugins/docker-compose
        fi
    done
}


# Function for configuring Docker MTU
docker_config ()
{
    # Checks if the /etc/docker directory exists and creates it if it
    if [[ ! -d /etc/docker ]]; then
        echo -e "${BLUE}Creating /etc/docker...${ENDCOL}"
        mkdir -p /etc/docker
    fi

    # Sets Docker mtu to 1442 in the daemon.json file
    echo -e "${BLUE}Setting MTU and enabling debugging...${ENDCOL}"
    { echo '{'; echo '   "mtu": 1442,'; echo '   "debug": true'; echo '}'; } >> /etc/docker/daemon.json

    echo -e "${BLUE}Starting and enabling docker daemon${ENDCOL}"
    # Starts and enables the Docker daemon service
    systemctl restart docker
    systemctl enable docker
    
}


# Creates the users given as argument and adds them to the docker group
create_users ()
{
    # Creates the 'docker' group
    groupadd -f docker

    # Loops through the users given as asrguments and adds them to the 'docker' group
    for user in $USERS; do
        if ! id -u "$user" &>/dev/null; then
            useradd "$user" -m
            echo -e "${GREEN}Created user \"${YELLOW}$user${ENDCOL}\"${ENDCOL}"
            
            usermod -aG docker "$user"

            echo -e "${GREEN}Added user \"${YELLOW}$user${ENDCOL}${GREEN}\" to docker group ${ENDCOL}"
        fi
    done
}


## Start of script ##


# Checks that script is running as root
if [[ $EUID != 0 ]]; then
    echo -e "${RED}Run script as root${ENDCOL}"
    exit 1
fi


# Print motd
motd


# Function for displaying help
help ()
{
   # Display help
   echo "Script for installing and configuring Docker plus creating users"
   echo
   echo "Syntax: install.sh [-h|-v|-u \"<usernames>\"]"
   echo
   echo "Options:"
   echo "-h     Show help menu."
   echo "-v     Verbose mode."
   echo "-u     Create user[s] given as \"<user1> <user2> ...\""
   echo
}

# Checks for arguments
# -u gets usernames
# -v sets verbose mode
while getopts "hvu:" option; do
    case $option in
        h) # Display help
            help
            exit
            ;;
        v) # Sets verbose mode
            VERBOSE=1
            #DEVNULL=""
            SILENT=""
            ;;
        u)
            USERS=$OPTARG;;

        \?) # Invalid option
            echo "Error: Invalid option"
            exit
            ;;
    esac
done


echo -e "${BLUE}Detecting distro and package manager...${ENDCOL}"
#if [[ $VERBOSE ]]; then check_pm >/dev/null else check_pm; fi
check_pm
echo -e "${GREEN}Distro:${ENDCOL} ${YELLOW}$DISTRO ${ENDCOL}"
echo -e "${GREEN}Package manager:${ENDCOL} ${YELLOW}$PM ${ENDCOL}"


# Installs Docker
echo -e "${BLUE}Starting Docker install...${ENDCOL}"
if [[ $VERBOSE == 0 ]]; then install_docker &>/dev/null; else install_docker; fi

# Checks if Docker was installed properly
if docker &>/dev/null; then
    DOCKER_VER=$(docker version | head -n 2 | tail -n 1 | cut -d " " -f 13)

    echo -e "${GREEN}Installed Docker version:${ENDCOL}${YELLOW} $DOCKER_VER${ENDCOL}"
fi


# Configures Docker
echo -e "${BLUE}Configuring Docker...${ENDCOL}"
docker_config
echo -e "${GREEN}Docker configured${ENDCOL}"


# Installs Docker Compose V1
# echo -e "${BLUE}Starting Docker Compose install...${ENDCOL}"
# install_compose_v1

# if docker-compose; then
#     TMP_COMPOSE_VER=$(docker-compose --version | cut -d " " -f 3)
#     COMPOSE_VER=${TMP_COMPOSE_VER::-1}

#     echo -e "${GREEN}Installed Docker Compose version:${ENDCOL} ${YELLOW} $COMPOSE_VER ${ENDCOL}"
# fi


# Creates users given as argument
if [[ -n $USERS ]]; then
    echo -e "${BLUE}Creating users...${ENDCOL}"
    create_users
    echo -e "${GREEN}Users created${ENDCOL}"
elif [[ -z $USERS ]]; then
    echo -e "${BLUE}No users passed${ENDCOL}"
else
    echo -e "${RED}Error${ENDCOL}"
fi


# Installs Docker Compose V2
echo -e "${BLUE}Installing Docker Compose v2...${ENDCOL}"
install_compose_v2

if docker compose &>/dev/null; then
    COMPOSE_VER=$(docker compose version | cut -d " " -f 4)

    echo -e "${GREEN}Installed Docker Compose version:${ENDCOL}${YELLOW} $COMPOSE_VER${ENDCOL}"
fi