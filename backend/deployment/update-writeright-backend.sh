#!/bin/bash

# Don't allow fail
set -e

export HOME=/var/lib/writeright-backend/git-home
PREFIX="sudo -u writeright-backend HOME=$HOME "
export TZ="Asia/Hong_Kong"

# Ensure git home directory exists
sudo mkdir -p $HOME
sudo chown writeright-backend:writeright-shared $HOME
sudo -u writeright-backend HOME=$HOME git config --global credential.helper 'cache --timeout=1800'
cd /opt/writeright-backend

$PREFIX git status

# Calculate required and available space (in KB)
REQUIRED=$(du -sk /opt/writeright-backend | awk '{print $1}')
AVAILABLE=$(df --output=avail /opt/writeright-backend | tail -1)

if (( AVAILABLE > REQUIRED * 2 )); then
    echo "Sufficient disk space. Creating backup..."
    sudo cp -a /opt/writeright-backend "/opt/writeright-backend-backup-$(date +%Y%m%d-%H%M%S)"
else
    echo "Warning: Not enough disk space for backup. Skipping backup step."
fi

args=""
read -p "Update submodules (y/N)? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    args="--recurse-submodules --jobs=10"
fi

echo "stopping backend..."
# Check if service is running and stop it
if sudo systemctl is-active --quiet writeright-backend.service; then
    sudo systemctl stop writeright-backend.service
    echo "Service stopped."
else
    echo "Service was not running."
fi

echo "Pulling latest changes..."
if ! $PREFIX git pull $args; then
    echo "Error: Git pull failed. Restarting service..."
    sudo systemctl start writeright-backend.service
    exit 1
fi

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Updating submodules to latest remote commits..."
    if ! $PREFIX git submodule update --remote --merge --recursive; then
        echo "Error: Submodule update failed. Restarting service..."
        sudo systemctl start writeright-backend.service
        exit 1
    fi
fi

echo "Updating dependencies..."
if ! $PREFIX /opt/writeright-backend/.venv/bin/pip install -r requirements.txt; then
    echo "Error: Pip install failed. Restarting service..."
    sudo systemctl start writeright-backend.service
    exit 1
fi

echo "Restarting..."
sudo systemctl start writeright-backend.service
sleep 3
sudo systemctl status writeright-backend.service

echo "See 'journalctl -xfeu writeright-backend.service' for more info"