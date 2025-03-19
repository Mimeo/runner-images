#!/bin/bash -e
################################################################################
##  File:  install-sbt.sh
##  Desc:  Install sbt and verify version
################################################################################

source $HELPER_SCRIPTS/install.sh

# Install latest sbt release
download_url=$(resolve_github_release_asset_url "sbt/sbt" "endswith(\".tgz\")" "latest")
archive_path=$(download_with_retry "$download_url")
tar zxf "$archive_path" -C /usr/share
ln -sf /usr/share/sbt/bin/sbt /usr/bin/sbt

# Verify installation and version
if ! command -v sbt &> /dev/null; then
    echo "❌ Sbt installation failed — command not found!"
    exit 1
fi

sbt_version=$(sbt --version | grep -oP '(?<=sbt ).*')
if [[ -z "$sbt_version" ]]; then
    echo "❌ Failed to retrieve Sbt version!"
    exit 1
fi

echo "✅ Sbt version $sbt_version installed successfully"

invoke_tests "Tools" "Sbt"
