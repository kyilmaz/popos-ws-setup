#!/bin/bash
# Pop!_OS 22.04 LTS Installation Script - 
# Lenovo Thinkpad E15 - Nvidia MX450
# Optimized for Development workloads
# Powered by Kyilmaz
# 

# --- Configuration ---
# Set to true to enable installation of specific steps
DO_STEP_1="PackageKit"
DO_STEP_2="System_Maintenance"
DO_STEP_3="Advanced_DevEnv"
DO_STEP_4="Web_Browsers"
DO_STEP_5="Containered_Env"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Logging ---
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# --- Script Setup ---
# Exit on error, treat unset variables as an error, and propagate exit status through pipes
set -euo pipefail
trap 'log_error "Script failed at line $LINENO with command: $BASH_COMMAND"' ERR

# --- Pre-flight Checks ---
clear
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Pop!_OS 22.04 Setup Script           ${NC}"
echo -e "${GREEN}  Lenovo Thinkpad E15 - Nvidia MX450    ${NC}"
echo -e "${GREEN}  Enhanced with Power Management        ${NC}"
echo -e "${BLUE}========================================${NC}"

if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root!"
    exit 1
fi

if ! sudo -v; then
    log_error "Sudo access required but not granted"
    exit 1
fi

# --- Helper Functions ---
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# --- Step 1: PackageKit Conflict Resolution ---
log "${BLUE}Starting ${DO_STEP_1}${NC}"
log "Handling PackageKit conflicts..."

if pgrep -x "packagekitd" > /dev/null; then
    log "Stopping PackageKit daemon..."
    sudo systemctl stop packagekit || log_warning "Could not stop packagekit via systemctl"
    sleep 2
    if pgrep -x "packagekitd" > /dev/null; then
        log "Force killing PackageKit processes..."
        sudo pkill -9 -f packagekitd || true
    fi
fi

if systemctl is-enabled --quiet packagekit; then
    log "Temporarily disabling PackageKit..."
    sudo systemctl disable packagekit || log_warning "Could not disable packagekit"
fi

log "Removing apt lock files..."
sudo rm -f /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock

log "Removing PackageKit..."
sudo apt-get -y remove --purge packagekit || log_warning "Failed to remove PackageKit"
log "${BLUE}${DO_STEP_1} Completed${NC}"

# --- Step 2: System Maintenance & Optimization ---
log "${BLUE}Starting ${DO_STEP_2}${NC}"
log "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y

if is_installed snapd; then
    log "Removing snapd..."
    sudo apt-get remove --purge snapd -y
    sudo apt-mark hold snapd
fi

log "Configuring power management..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

log "night-light settings to always on..."
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 24
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000

log "Applying performance optimizations..."
if ! is_installed tuned; then
    log "Installing tuned..."
    sudo apt-get install -y tuned tuned-utils
fi
sudo systemctl enable tuned --now
sudo tuned-adm profile throughput-performance

log "Setting kernel parameters..."
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
fi

log "Installing essential tools..."
sudo apt-get install -y curl wget git build-essential dkms software-properties-common apt-transport-https ca-certificates gnupg lsb-release vim nano htop neofetch tree apt-file locate mlocate jq

log "Installing Additional Fonts..."
sudo apt-get install -y fonts-ipafont-gothic fonts-ipafont-mincho fonts-wqy-microhei fonts-wqy-zenhei fonts-indic

sudo updatedb

log "Installing multimedia tools..."
sudo apt-get install -y ffmpeg obs-studio shotcut handbrake vlc

log "Installing system tools..."
sudo apt-get install -y filezilla gnome-disk-utility gparted tilix flameshot ncdu ranger fzf glances iotop tmux remmina remmina-plugin-rdp p7zip-full unzip gnome-tweaks dconf-editor postgresql-client redis-tools nginx

log "Installing RustDesk..."
RUSTDESK_VERSION=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep -Po '"tag_name": "\K[^"]*')
wget "https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-${RUSTDESK_VERSION}-x86_64.deb" -O /tmp/rustdesk.deb
sudo apt-get install -y /tmp/rustdesk.deb
rm /tmp/rustdesk.deb

log "${BLUE}${DO_STEP_2} Completed${NC}"

# --- Step 3: Development Environment ---
log "${BLUE}Starting ${DO_STEP_3}${NC}"

if ! nvidia-smi >/dev/null 2>&1; then
    log "Installing Nvidia drivers..."
    sudo apt-get install -y nvidia-driver-535 nvidia-dkms-535
fi

log "Installing programming languages..."

if ! command -v rustc &> /dev/null; then
    log "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

if ! command -v go &> /dev/null; then
    log "Installing Go..."
    sudo apt-get install -y golang-go
fi

if ! command -v node &> /dev/null; then
    log "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

if [ ! -d "$HOME/anaconda3" ]; then
    log "Installing Anaconda Python Distribution..."
    ANACONDA_INSTALLER="Anaconda3-2024.02-1-Linux-x86_64.sh"
    wget "https://repo.anaconda.com/archive/$ANACONDA_INSTALLER" -O /tmp/anaconda.sh
    bash /tmp/anaconda.sh -b -p "$HOME/anaconda3"
    rm /tmp/anaconda.sh
    "$HOME/anaconda3/bin/conda" init bash
    export PATH="$HOME/anaconda3/bin:$PATH"

    log "Installing CUDA toolkit..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb
    sudo dpkg -i /tmp/cuda-keyring.deb
    rm /tmp/cuda-keyring.deb
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-2

    log "Configuring conda channels..."
    "$HOME/anaconda3/bin/conda" config --add channels conda-forge
    "$HOME/anaconda3/bin/conda" config --set channel_priority strict

    log "Installing conda packages..."
    "$HOME/anaconda3/bin/conda" install -y jupyter notebook matplotlib pandas numpy scipy scikit-learn seaborn plotly bokeh opencv transformers nltk spacy pyspark

    log "Installing pip packages..."
    "$HOME/anaconda3/bin/pip" install huggingface_hub streamlit gradio fastapi uvicorn torchvision torchaudio

    log "Setting up Jupyter..."
    "$HOME/anaconda3/bin/python" -m ipykernel install --user --name=base --display-name "Python (Conda Base)"
fi

log "Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --yes --dearmor > /tmp/packages.microsoft.gpg
sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm /tmp/packages.microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

log "${BLUE}${DO_STEP_3} Completed${NC}"

# --- Step 4: Web Browsers ---
log "${BLUE}Starting ${DO_STEP_4}${NC}"
log "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
sudo apt-get update
sudo apt-get install -y google-chrome-stable
log "${BLUE}${DO_STEP_4} Completed${NC}"

# --- Step 5: Containerized Environments ---
log "${BLUE}Starting ${DO_STEP_5}${NC}"
log "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Configuring Docker..."
sudo mkdir -p /opt/containers/{docker,portainer}
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "/opt/containers/docker",
  "storage-driver": "overlay2"
}
EOF
sudo usermod -aG docker "$USER"
sudo systemctl enable docker --now

log "Installing Rancher Desktop..."
curl -s https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | gpg --yes --dearmor | sudo dd status=none of=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./' | sudo tee /etc/apt/sources.list.d/isv-rancher-stable.list > /dev/null
sudo apt-get update
sudo apt-get install -y rancher-desktop

log "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

log "${BLUE}${DO_STEP_5} Completed${NC}"

# --- Finalization ---
log "Setting up shell configuration..."
if ! grep -q "# Custom aliases" ~/.bashrc; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d)
    cat << 'EOF' >> ~/.bashrc

# Custom aliases
alias ll='ls -alF'
alias c='clear'
alias ports='netstat -tulanp'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

# Python aliases
alias py='python3'

# Container aliases
alias dc='docker compose'
alias dps='docker ps'

# Interactive operation...
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'
alias c='clear'

# Default to human readable figures
alias df='df -h'
alias du='du -h'

# Misc
alias less='less -r'                          # raw control characters
alias whence='type -a'                        # where, of a sort
alias grep='grep --color'                     # show differences in colour
alias egrep='egrep --color=auto'              # show differences in colour
alias fgrep='fgrep --color=auto'              # show differences in colour

# Some shortcuts for different directory listings
alias ls='ls -hF --color=tty'                 # classify files in colour
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'

EOF
fi

cp ~/.profile ~/.profile.backup.$(date +%Y%m%d)
cat << 'EOF' >> ~/.profile


export TMOUT=

export LC_ALL=C

export LANG=en_US.UTF-8

# Function remotedisplay get remote XDISPLAY running
function remotedisplay() {
  remoteip=$(who am i | awk '{print $NF}' | tr -d ')''(' )
}
remotedisplay
DISPLAY=$remoteip:0.0; export DISPLAY

export PS1="\033[38;5;209m\]┌──[\033[38;5;141m\]\u\033[38;5;209m\]:\033[38;5;105m\]\h\033[38;5;231m\]\W\033[38;5;209m\]]\n\033[38;5;209m\]└─\\[\033[38;5;209m\]$\[\033[37m\] "

export PATH="$HOME/.cargo/bin:$HOME/anaconda3/bin:$PATH"

EOF

log "Installing Flatpak support..."
sudo apt-get install -y flatpak gnome-software-plugin-flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

log "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get autoclean

# --- Re-enable PackageKit ---
log "Re-enabling PackageKit..."
sudo apt-get -y install --reinstall packagekit gnome-software
sudo systemctl unmask packagekit
sudo systemctl enable packagekit
sudo systemctl start packagekit

# --- Completion ---
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!                ${NC}"
echo -e "${GREEN}  Please reboot your system to ensure   ${NC}"
echo -e "${YELLOW}  all changes take effect.              ${NC}"
echo -e "${GREEN}========================================${NC}"
