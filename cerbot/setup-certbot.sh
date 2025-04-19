#!/bin/bash

#
# setup-certbot.sh - Automated SSL certificate setup with certbot
#

set -e

function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --help                  Show this help message"
    echo "  --domain DOMAIN         Domain name to obtain certificate for"
    echo "  --email EMAIL           Email address for Let's Encrypt notifications"
    echo "  --webroot PATH          Path to webroot for verification (default: /var/www/html)"
    echo "  --nginx                 Configure for Nginx web server"
    echo "  --apache                Configure for Apache web server"
    echo "  --staging               Use Let's Encrypt staging environment for testing"
}

if [[ "$1" == "--help" || $# -eq 0 ]]; then
    show_usage
    exit 0
fi

echo  "Starting Certbot installation and certificate setup..."

function install_certbot {
    echo "Installing Cerbot..."

    # Detect OS
    if [ -f /etc/debian_version ]; then
    # Debian/Ubunut
        apt-get update
        apt-get install -y certbot python3-certbot-nginx python3-certbot-apache
    elif [ -f /etc/redhat-release ]; then
        if grep -q "release 7" /etc/readhat-release; then
            yum install -y epel-release
            yum install -y certbot certbot-nginx certbot-apache
        else
            dnf install -y epel-release
            dnf install -y certbot python3-certbot-nginx python3-certbot-apache
        fi
    else
        echo "Unsupported OS. Please install Certbot manually."
        exit 1
    fi

    # Verify Installation
    if command -v certbot &> /dev/null; then
        echo "Certbot installed successfully."
    else
        echo "Certbot installation failed."
        exit 1
    fi
}

function generate_certificate {
    echo "Generating SSL certificates..."

    local cmd="certbot certonly"


    if [ -n "$EMAIL" ]; then
        cmd="$cmd --email $EMAIL"
    else
        cmd="$cmd --register-unsafely-without-email"
    fi

    # add domains
    for domain in "${DOMAINS[@]}"; do
        cmd="$cmd -d $domain"
    done

    if [ "$WEB_SERVER" == "nginx" ]; then
        cmd="$cmd --nginx"
    elif [ "$WEB_SERVER" == "apache"]; then
        cmd="$cmd --apache"
    fi

    if [ "$STAGING" -eq 1 ]; then
        cmd="$cmd --staging"
    fi

    cmd="$cmd --non-interactive --agree-tos"

    echo "Executing: $cmd"
    eval "$cmd"

    echo "Certificate generation complete."
}