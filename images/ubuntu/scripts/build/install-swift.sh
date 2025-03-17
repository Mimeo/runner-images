#!/bin/bash -e
################################################################################
##  File:  install-swift.sh
##  Desc:  Install Swift with improved GPG handling
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
rm -rf ~/.gnupg
# Verifying PGP signature using official Swift PGP key. Referring to https://www.swift.org/install/linux/#Installation-via-Tarball
# Define Swift PGP keys
swift_keys=(
    '7463A81A4B2EEA1B551FFBCFD441C977412B37AD'
    '1BE1E29A084CB305F397D62A9F597F4D21A56D5F'
    'A3BAFD3556A59079C06894BD63BC1CFE91D306C6'
    '5E4DF843FB065D7F7E24FBA2EF5430F071E1B235'
    '8513444E2DA36B7C1659AF4D7638F1FB2B2B08C4'
    'A62AE125BBBFBB96A6E042EC925CC1CCED3D1561'
    '8A7495662C3CD4AE18D95637FAF6989E1BC16FEA'
    'E813C892820A6FA13755B268F167DF1ACF9CE069'
)

# Attempt to fetch keys from keyserver with retries
keyserver="hkps://keyserver.ubuntu.com"
for key in "${swift_keys[@]}"; do
    echo "Importing key: $key"
    if ! gpg --keyserver "$keyserver" --recv-keys "$key"; then
        echo "Failed to fetch key $key from $keyserver. Attempting manual import..."
        curl -fsSL https://swift.org/keys/all-keys.asc | gpg --import || {
            echo "Failed to import Swift GPG keys." >&2
            exit 1
        }
    fi
done

gpg --keyserver "$keyserver" --refresh-keys Swift || echo "Warning: Failed to refresh Swift keys."

# Download and verify signature
signature_path=$(download_with_retry "${archive_url}.sig")
if ! gpg --batch --verify "$signature_path" "$archive_path"; then
    echo "Swift tarball signature verification failed!" >&2
    exit 1
fi

# Clean up Swift PGP public key with temporary keyring
rm -rf ~/.gnupg

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
