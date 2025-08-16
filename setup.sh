#!/bin/bash

# Clear Screen
tput reset 2>/dev/null || clear

# Colours (or Colors in en_US)
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NORMAL='\033[0m'

# Abort Function
function abort(){
    [ ! -z "$@" ] && echo -e ${RED}"${@}"${NORMAL}
    exit 1
}

# Banner
function __bannerTop() {
	echo -e \
	${GREEN}"
	██████╗░██╗░░░██╗███╗░░░███╗██████╗░██████╗░██╗░░██╗██╗
	██╔══██╗██║░░░██║████╗░████║██╔══██╗██╔══██╗╚██╗██╔╝██║
	██║░░██║██║░░░██║██╔████╔██║██████╔╝██████╔╝░╚███╔╝░██║
	██║░░██║██║░░░██║██║╚██╔╝██║██╔═══╝░██╔══██╗░██╔██╗░██║
	██████╔╝╚██████╔╝██║░╚═╝░██║██║░░░░░██║░░██║██╔╝╚██╗██║
	╚═════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝
	"${NORMAL}
}

# Welcome Banner
printf "\e[32m" && __bannerTop && printf "\e[0m"

# Minor Sleep
sleep 1

if [[ "$OSTYPE" == "linux-gnu" ]]; then

    if command -v apt > /dev/null 2>&1; then

        echo -e ${PURPLE}"Ubuntu/Debian Based Distro Detected"${NORMAL}
        sleep 1
        echo -e ${BLUE}">> Updating apt repos..."${NORMAL}
        sleep 1
	    sudo apt -y update || abort "Setup Failed!"
	    sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1
        sudo apt install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar uudeview mpack arj cabextract device-tree-compiler liblzma-dev python3-pip brotli liblz4-tool axel gawk aria2 detox cpio rename liblz4-dev jq git-lfs || abort "Setup Failed!"

    elif command -v dnf > /dev/null 2>&1; then

        echo -e ${PURPLE}"Fedora Based Distro Detected"${NORMAL}
        sleep 1
        echo -e ${BLUE}">> Enabling COPR repository for unace..."${NORMAL}
        sleep 1
        sudo dnf copr enable -y caarmi/unace || abort "Failed to enable COPR repository!"
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

	    # "dnf" automatically updates repos before installing packages
        sudo dnf install -y unace unrar zip unzip sharutils uudeview arj cabextract file-roller dtc python3-pip brotli axel aria2 detox cpio lz4 python3-devel xz-devel p7zip p7zip-plugins git-lfs || abort "Setup Failed!"

    elif command -v pacman > /dev/null 2>&1; then

        echo -e ${PURPLE}"Arch or Arch Based Distro Detected"${NORMAL}
        sleep 1
	    echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	    sleep 1

        sudo pacman -Syyu --needed --noconfirm >/dev/null || abort "Setup Failed!"
        sudo pacman -Sy --noconfirm unace unrar p7zip sharutils uudeview arj cabextract file-roller dtc brotli axel gawk aria2 detox cpio lz4 jq git-lfs || abort "Setup Failed!"

    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then

    echo -e ${PURPLE}"macOS Detected"${NORMAL}
    sleep 1
	echo -e ${BLUE}">> Installing Required Packages..."${NORMAL}
	sleep 1
    brew install protobuf xz brotli lz4 aria2 detox coreutils p7zip gawk git-lfs || abort "Setup Failed!"

fi

sleep 1

# SSH Key Setup for GitHub
echo -e ${BLUE}">> Setting up SSH key for GitHub..."${NORMAL}
sleep 1

# Check if SSH key already exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e ${BLUE}">> Please enter your GitHub email address:"${NORMAL}
    read -p "Email: " github_email
    
    # Validate email format (basic check)
    if [[ ! "$github_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        abort "Invalid email format!"
    fi
    
    echo -e ${BLUE}">> Generating new SSH key..."${NORMAL}
    ssh-keygen -t ed25519 -C "$github_email" -f ~/.ssh/id_ed25519 -N "" || abort "Failed to generate SSH key!"
    
    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
else
    echo -e ${GREEN}">> SSH key already exists"${NORMAL}
fi

# Display public key
echo -e ${PURPLE}">> Your SSH public key:"${NORMAL}
echo -e ${GREEN}"$(cat ~/.ssh/id_ed25519.pub)"${NORMAL}
echo ""
echo -e ${BLUE}">> Please follow these steps:"${NORMAL}
echo -e "1. Copy the SSH public key above"
echo -e "2. Go to GitHub.com → Settings → SSH and GPG keys"
echo -e "3. Click 'New SSH key'"
echo -e "4. Paste your key and give it a title"
echo -e "5. Click 'Add SSH key'"
echo ""
echo -e ${PURPLE}">> Press ENTER when you have added the key to GitHub..."${NORMAL}
read -r

# Test SSH connectivity to GitHub
echo -e ${BLUE}">> Testing SSH connectivity to GitHub..."${NORMAL}
sleep 1

# Test connection (this will always exit with code 1, but we check the output)
ssh_test=$(ssh -T git@github.com 2>&1)
if echo "$ssh_test" | grep -q "successfully authenticated"; then
    echo -e ${GREEN}">> SSH connection to GitHub successful!"${NORMAL}
elif echo "$ssh_test" | grep -q "Permission denied"; then
    echo -e ${RED}">> SSH connection failed. Please check your SSH key setup."${NORMAL}
    echo -e ${RED}">> Make sure you added the key to your GitHub account."${NORMAL}
    abort "SSH setup failed!"
else
    echo -e ${PURPLE}">> SSH test output: $ssh_test"${NORMAL}
    echo -e ${PURPLE}">> If you see your GitHub username above, SSH is working correctly."${NORMAL}
fi

sleep 1

# Install `uv`
echo -e ${BLUE}">> Installing uv for python packages..."${NORMAL}
sleep 1
bash -c "$(curl -sL https://astral.sh/uv/install.sh)" || abort "Setup Failed!"

# Done!
echo -e ${GREEN}"Setup Complete!"${NORMAL}

# Exit
exit 0
