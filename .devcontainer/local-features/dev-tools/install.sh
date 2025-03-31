#!/usr/bin/env bash

USERNAME=${USERNAME:-"vscode"}

set -eux

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
    err 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

###########################################
# Helper Functions
###########################################

apt-get-update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check-packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt-get-update
        apt-get -y install --no-install-recommends "$@"
    fi
}

###########################################
# Install Feature
###########################################

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg

sh -c 'echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/debian/$(lsb_release -rs | cut -d'.' -f 1)/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'

check-packages \
    poppler-utils \
    azure-functions-core-tools-4 \
    libsecret-1-0

echo 'dev-tools script has completed!'
