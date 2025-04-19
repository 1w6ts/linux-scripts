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