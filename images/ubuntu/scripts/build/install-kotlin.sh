#!/bin/bash -e
################################################################################
##  File:  install-kotlin.sh
##  Desc:  Install Kotlin
##  Supply chain security: Kotlin - checksum validation
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

KOTLIN_ROOT="/usr/share/kotlin"
BIN_PATH="/usr/local/bin"

# Fetch the latest Kotlin compiler release
download_url=$(resolve_github_release_asset_url "JetBrains/kotlin" "contains(\"kotlin-compiler\") and endswith(\".zip\")" "latest")
archive_path=$(download_with_retry "$download_url")

# Supply chain security - Kotlin checksum validation
kotlin_hash_file=$(download_with_retry "${download_url}.sha256")
kotlin_hash=$(cat "$kotlin_hash_file")
use_checksum_comparison "$archive_path" "$kotlin_hash"

# Extract Kotlin to the target location
mkdir -p "$KOTLIN_ROOT"
unzip -qq "$archive_path" -d "$KOTLIN_ROOT"
rm "$KOTLIN_ROOT/kotlinc/bin/"*.bat

# Ensure all Kotlin binaries are symlinked properly
for file in "$KOTLIN_ROOT/kotlinc/bin/"*; do
    ln -sf "$file" "$BIN_PATH/$(basename "$file")"
done

# Verify that binaries are in the PATH
echo "Verifying Kotlin installation:"
command -v kotlin || echo "Kotlin binary not found!"
command -v kotlinc || echo "Kotlinc binary not found!"
command -v kapt || echo "Kapt binary not found!"
command -v kotlin-dce-js || echo "kotlin-dce-js binary not found!"

# Run tests to ensure everything works
invoke_tests "Tools" "Kotlin"


