#!/bin/bash -e
################################################################################
##  File:  install-heroku.sh
##  Desc:  Install Heroku CLI. Based on instructions found here: https://devcenter.heroku.com/articles/heroku-cli
################################################################################

REPO_URL="https://cli-assets.heroku.com/channels/stable/apt"
GPG_KEY="/usr/share/keyrings/heroku-archive-keyring.gpg"
REPO_PATH="/etc/apt/sources.list.d/heroku.list"

# Add Heroku GPG key
curl -fsSL "${REPO_URL}/release.key" | gpg --dearmor | sudo tee $GPG_KEY > /dev/null

# Add Heroku repository to apt sources
echo "deb [signed-by=$GPG_KEY] $REPO_URL ./" | sudo tee $REPO_PATH

# Install Heroku CLI
sudo apt-get update
sudo apt-get install -y heroku

# Clean up Heroku's apt repository files
sudo rm -f $REPO_PATH
sudo rm -f $GPG_KEY

# Test installation
heroku --version

