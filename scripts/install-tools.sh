#!/bin/bash

# Script to install additional tools for reNgine development
# Core Go tools are installed in Dockerfile, this script handles git-cloned tools

set -e

echo "=== Installing reNgine Tools ==="

CONTAINER_NAME="rengine-celery-1"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Celery container is not running. Start it first with: make dev-up"
    exit 1
fi

echo "Installing tools in container: $CONTAINER_NAME"

echo "[0/6] Installing browser dependencies..."
docker exec $CONTAINER_NAME bash -c "
    add-apt-repository -y ppa:mozillateam/ppa
    cat > /etc/apt/preferences.d/mozilla-firefox <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox
Pin: version 1:1snap1-0ubuntu2
Pin-Priority: -1
EOF
    apt update -qq
    apt install -y -qq firefox
"

# Download wordlists
echo "[1/6] Downloading wordlists..."
docker exec $CONTAINER_NAME bash -c "
    mkdir -p /usr/src/wordlist
    if [ ! -f /usr/src/wordlist/dicc.txt ]; then
        wget -q https://raw.githubusercontent.com/maurosoria/dirsearch/master/db/dicc.txt -O /usr/src/wordlist/dicc.txt
    fi
"

# Clone EyeWitness
echo "[2/6] Cloning EyeWitness..."
docker exec $CONTAINER_NAME bash -c "
    if [ ! -d /usr/src/github/EyeWitness ]; then
        git clone -q https://github.com/FortyNorthSecurity/EyeWitness /usr/src/github/EyeWitness
    fi
    pip install -q psutil fuzzywuzzy selenium pyvirtualdisplay
"

# Clone vulscan
echo "[3/6] Cloning vulscan..."
docker exec $CONTAINER_NAME bash -c "
    if [ ! -d /usr/src/github/scipag_vulscan ]; then
        git clone -q https://github.com/scipag/vulscan /usr/src/github/scipag_vulscan
        ln -sf /usr/src/github/scipag_vulscan /usr/share/nmap/scripts/vulscan
    fi
"

# Install WhatWeb
echo "[4/6] Cloning WhatWeb..."
docker exec $CONTAINER_NAME bash -c "
    if [ ! -d /usr/src/github/WhatWeb ]; then
        git clone -q https://github.com/urbanadventurer/WhatWeb /usr/src/github/WhatWeb
    fi
    cd /usr/src/github/WhatWeb && gem install bundler -N && bundle install
"

# Clone CMSeeK
echo "[5/6] Cloning CMSeeK..."
docker exec $CONTAINER_NAME bash -c "
    if [ ! -d /usr/src/github/CMSeeK ]; then
        git clone -q https://github.com/Tuhinshubhra/CMSeeK /usr/src/github/CMSeeK
    fi
    pip install -q -r /usr/src/github/CMSeeK/requirements.txt
"

# Install Nuclei templates
echo "[6/6] Installing Nuclei templates..."
docker exec $CONTAINER_NAME bash -c "
    nuclei -update-templates
"

echo ""
echo "=== Tools Installation Complete ==="
echo ""
echo "You can now use: make dev-restart"
