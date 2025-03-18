# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh

KOTLIN_ROOT="/usr/share"

# Pin to Kotlin 1.6.x for kotlin-dce-js compatibility
download_url=$(resolve_github_release_asset_url "JetBrains/kotlin" "contains(\"kotlin-compiler-1.6\") and endswith(\".zip\")" "latest")
archive_path=$(download_with_retry "$download_url")

# Supply chain security - Kotlin
kotlin_hash_file=$(download_with_retry "${download_url}.sha256")
kotlin_hash=$(cat "$kotlin_hash_file")
use_checksum_comparison "$archive_path" "$kotlin_hash"

# Extract and install
unzip -qq "$archive_path" -d $KOTLIN_ROOT
rm $KOTLIN_ROOT/kotlinc/bin/*.bat
ln -sf $KOTLIN_ROOT/kotlinc/bin/* /usr/bin

# Run tests to ensure all binaries work, including kotlin-dce-js
invoke_tests "Tools" "Kotlin"

