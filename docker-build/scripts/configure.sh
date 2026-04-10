#!/bin/bash

# Exit on error
set -e

echo "--- Installing Tailscale ---"


echo "--- Installing System Dependencies & Build Essentials ---"
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    curl \
    git \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxml2-utils \
    liblzma-dev \
    uuid-dev \
    ufw \
    iptables-persistent \
    netfilter-persistent \
    wget \
    ca-certificates \
    gnupg

sudo apt update; sudo apt install make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# 1. CUDA Toolkit
echo "--- Installing CUDA Toolkit ---"
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit

# 2. Pyenv Installation
echo "--- Installing pyenv ---"
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
fi

# Export paths for current session
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Persist pyenv to bashrc
if ! grep -q "export PYENV_ROOT" ~/.bashrc; then
    echo -e '\n# Pyenv Configuration' >> ~/.bashrc
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
fi

# 3. Python 3.12.13
echo "--- Installing Python 3.12.13 ---"
pyenv install 3.12.13
pyenv global 3.12.13
pyenv rehash

# 4. Comfy-CLI
echo "--- Installing comfy-cli ---"
pip install --upgrade pip
pip install comfy-cli
pyenv rehash

# 5. ComfyUI Setup
echo "--- Installing ComfyUI ---"
# Directory handled internally by comfy-cli
comfy install

# 6. Configure comfy-cli
echo "--- Configuring comfy-cli defaults ---"
# Setting default path and launch arguments
comfy set-default /home/user/comfy/ComfyUI --launch-extras="--listen 0.0.0.0"

# 7. Firewall & Networking
echo "--- Configuring UFW ---"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow in on tailscale0
echo "y" | sudo ufw enable

# 8. Port Redirection (80 -> 8188) & Persistence
echo "--- Setting up Port 80 persistence with netfilter-persistent ---"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8188

# Save rules and ensure service is active for persistence
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent

echo "--- Setting up docker and replicate cog ---"
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo curl -o /usr/local/bin/cog -L https://github.com/replicate/cog/releases/latest/download/cog_`uname -s`_`uname -m`
sudo chmod +x /usr/local/bin/cog

echo "--------------------------------------------------------"
echo "Setup Complete."
echo "1. Run 'source ~/.bashrc' to refresh your current terminal."
echo "2. Your Port 80 -> 8188 redirect is now persistent via netfilter-persistent."
echo "--------------------------------------------------------"