#!/bin/bash
#
# setup-nginx.sh - Automated NGINX installation & configuration
#

# exit on error
set -e

function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo " --help    Show this help message"
}

if [[ "$1" == "--help"]]; then
show_usage
exit 0
fi

echo "starting nginx installation..."

function install_nginx {
    echo "Installing nginx..."

    # detect OS
    if [ -f /etc/debian_version ]; then
    # debian/ubuntu
        apt-get update
        apt-get install -y nginx
    elif [ -f /etc/redhat-release]; then
    # centos/rhel
        yum install -y epel-release
        yum install -y nginx
    else
        echo "Unsupported OS. Please install Nginx manually."
        exit 1
    fi

    # verify installation
    if command -v nginx &> /dev/null; then
        echo "Nginx installed successfully!"
    else
        echo "Nginx installation failed!"
        exit 1
    fi
}

install_nginx