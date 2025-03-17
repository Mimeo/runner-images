#!/bin/bash -e
################################################################################
##  File:  install-swift.sh
##  Desc:  Install Swift with improved GPG handling, auto-key refresh, and verification
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/install.sh
source $HELPER_SCRIPTS/etc-environment.sh

# Install
image_label="ubuntu$(lsb_release -rs)"
swift_version=$(curl -fsSL "https://api.github.com/repos/apple/swift/releases/latest" | jq -r '.tag_name | match("[0-9.]+").string')
swift_release_name="swift-${swift_version}-RELEASE-${image_label}"

archive_url="https://swift.org/builds/swift-${swift_version}-release/${image_label//./}/swift-${swift_version}-RELEASE/${swift_release_name}.tar.gz"
archive_path=$(download_with_retry "$archive_url")

# Set up persistent GPG keyring to avoid CI/CD wipe issues
export GNUPGHOME="/tmp/gnupg"
mkdir -p $GNUPGHOME
chmod 700 $GNUPGHOME

# Fetch latest Swift keys with auto-refresh
curl -fsSL https://swift.org/keys/all-keys.asc | gpg --import || {
    echo "Failed to import Swift GPG keys." >&2
    exit 1
}

# Ensure keys are refreshed and valid
if ! gpg --keyserver hkps://keyserver.ubuntu.com --refresh-keys Swift; then
    echo "Warning: Failed to refresh Swift keys. Trying backup refresh..."
    curl -fsSL https://swift.org/keys/all-keys.asc | gpg --import
fi

# Trust new Swift keys explicitly
for key in $(gpg --list-keys --with-colons | grep 'swift-infrastructure' | awk -F: '{print $5}'); do
    echo "Setting ultimate trust for key: $key"
    gpg --batch --yes --edit-key "$key" trust quit <<< "5"
done

# Download and verify signature
signature_path=$(download_with_retry "${archive_url}.sig")

# Detailed verification check with error handling
if ! gpg --batch --verify --verbose "$signature_path" "$archive_path"; then
    echo "Swift tarball signature verification failed!" >&2
    echo "Dumping GPG keyring for diagnostics:"
    gpg --list-keys
    exit 1
fi

# Clean up Swift PGP public key with temporary keyring
rm -rf $GNUPGHOME

# Extract and install Swift
tar xzf "$archive_path" -C /tmp

SWIFT_INSTALL_ROOT="/usr/share/swift"
swift_bin_root="$SWIFT_INSTALL_ROOT/usr/bin"
swift_lib_root="$SWIFT_INSTALL_ROOT/usr/lib"

mv "/tmp/${swift_release_name}" $SWIFT_INSTALL_ROOT
mkdir -p /usr/local/lib

ln -s "$swift_bin_root/swift" /usr/local/bin/swift
ln -s "$swift_bin_root/swiftc" /usr/local/bin/swiftc
ln -s "$swift_lib_root/libsourcekitdInProc.so" /usr/local/lib/libsourcekitdInProc.so

set_etc_environment_variable "SWIFT_PATH" "${swift_bin_root}"

invoke_tests "Common" "Swift"
