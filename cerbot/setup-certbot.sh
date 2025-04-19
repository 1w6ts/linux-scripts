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