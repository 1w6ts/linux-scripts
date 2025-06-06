#!/bin/bash

#
# setup-certbot.sh - Automated SSL certificate setup with certbot
#

set -e

DOMAINS=()
EMAIL=""
WEBROOT_PATH="/var/www/html"
WEB_SERVER=""
AUTH_METHOD="WEB_ROOT"
STAGING=0
BACKUP=1

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

function configure_renewal {
    echo "Configuring automatic certificate renewal..."

    # create a systemd timer for renewal if it doesn't exist
    if [ ! -f /etc/systemd/system/cerbot-renewal.timer ]; then
        cat > /etc/systemd/system/certbot-renewal-timer << EOF
[Unit]
Description=Timer for Certbot renewal

[Timer]
OnCalendar=*-*-* 00,12:00:00
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
        cat > /etc/systemd/system/certbot-renewal.service << EOF
[Unit]
Description=Certbot Renewal Service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cerbot renew --quiet --no-self-upgrade
ExecStartPost=/bin/systemctl reload ${WEB_SERVER}.service

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable certbot-renewal.timer
        system start certbot-renewal.timer

        echo "Automatic renewal configured with systemd timer"
    else
        echo "Renewal timer already exists, skipping..."
    fi

    # test renewal configuration
    echo "Testing certificate renewal configuration..."
    certbot renew --dry-run

    echo "Renewal configuration complete."
}

function backup_certificates {
  echo "Backing up existing certificates..."
  
  local backup_dir="/etc/letsencrypt/backup"
  local date_suffix=$(date +"%Y%m%d%H%M%S")
  
  # create backup directory if it doesn't exist
  mkdir -p "$backup_dir"
  
  # check if there are existing certificates
  if [ -d /etc/letsencrypt/live ]; then
    tar -czf "$backup_dir/letsencrypt-$date_suffix.tar.gz" -C / etc/letsencrypt/live etc/letsencrypt/archive etc/letsencrypt/renewal
    
    echo "Certificates backed up to $backup_dir/letsencrypt-$date_suffix.tar.gz"
  else
    echo "No existing certificates found to backup"
  fi
}

function validate_domain {
  local domain=$1
  
  # domain validation regex
  if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid domain name: $domain"
    return 1
  fi
  
  return 0
}

function validate_email {
  local email=$1
  
  if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Invalid email address: $email"
    return 1
  fi
  
  return 0
}

function validate_webroot {
  local path=$1
  
  # check if path exists
  if [ ! -d "$path" ]; then
    echo "Webroot path does not exist: $path"
    return 1
  fi
  
  # check if path is writable
  if [ ! -w "$path" ]; then
    echo "Webroot path is not writable: $path"
    return 1
  fi
  
  return 0
}