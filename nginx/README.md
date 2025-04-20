# Nginx Auto Setup Script

An automated bash script for installing and configurint Nginx with sensible defaults, security settings, anf performance optimizations.

## Features

- Cross-platform installation (Debian/Ubuntu and CentOS/RHEL)
- Customizable HTTP & HTTPS ports
- Security headers config
- Basic protections through rate limiting
- Performance optimizations
- Automatic service conf

## Installation

```bash
# clone this repo
git clone https://github.com/1w6ts/linux_scripts
cd linux_scripts

# make the shell file executable
chmod +x setup-nginx.sh
# alternatively, you can use
chmod 777 setup-nginx.sh
```

## Usage

```bash
sudo ./setup-nginx.sh [options]
```

## Options

- `--help`: Show usage information
- `--http-port PORT`: Specify custom HHTP port (default is 80)
- `--https-port PORT`: Specify custom HTTPS port (defauls is 443)
- `--enable-https`: Enable HTTPS redirection
- `--skip-ssl`: Skip SSL configuratiob

## Examples

Install Nginx with default settings:

```bash
sudo ./setup-nginx.sh
```

Install Nginx with custom ports:

```bash
sudo ./setup-nginx.sh --http-port 8080 --https-port 8443
```

Enable HTTPS redirection:

```bash
sudo ./nginx-setup.sh --enable-https
```
