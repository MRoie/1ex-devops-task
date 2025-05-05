#!/bin/bash
set -e

echo "======================================================="
echo "     Minikube Local Access Setup Wizard (Linux/macOS)" 
echo "======================================================="
echo

# Check for sudo privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script needs sudo privileges to modify /etc/hosts"
  echo "Please run with sudo"
  exit 1
fi

echo "Detecting your active network interface..."
echo

# Get the default interface and its IP
if command -v ip > /dev/null; then
  DEFAULT_ROUTE=$(ip route | grep default | head -n1)
  DEFAULT_IFACE=$(echo "$DEFAULT_ROUTE" | awk '{print $5}')
  LOCAL_IP=$(ip addr show "$DEFAULT_IFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
elif command -v ifconfig > /dev/null; then
  # Fallback to ifconfig
  DEFAULT_IFACE=$(route -n get default | grep interface | awk '{print $2}')
  LOCAL_IP=$(ifconfig "$DEFAULT_IFACE" | grep "inet " | awk '{print $2}')
fi

if [ -z "$LOCAL_IP" ]; then
  echo "Could not automatically detect your local IP."
  read -p "Please enter your local network IP address: " LOCAL_IP
else
  echo "Detected IP: $LOCAL_IP on interface $DEFAULT_IFACE"
  read -p "Use this IP? [Y/n]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    read -p "Please enter your local network IP address: " LOCAL_IP
  fi
fi

DOMAIN="1ex.hire.roie.local"
echo
echo "Using domain: $DOMAIN"
echo

echo "Setting up hosts file..."
if grep -q "$DOMAIN" /etc/hosts; then
  echo "Entry for $DOMAIN already exists in hosts file. Updating..."
  sed -i.bak "s/^.*$DOMAIN.*$/$LOCAL_IP $DOMAIN/" /etc/hosts
else
  echo "$LOCAL_IP $DOMAIN" >> /etc/hosts
fi

echo "Checking if Minikube is running..."
if ! minikube status >/dev/null 2>&1; then
  echo "Starting Minikube..."
  minikube start
else
  echo "Minikube is already running."
fi

echo "Checking if ingress addon is enabled..."
if ! minikube addons list | grep -q "ingress.*enabled"; then
  echo "Enabling ingress addon..."
  minikube addons enable ingress
else
  echo "Ingress addon is already enabled."
fi

echo
echo "Starting Minikube tunnel with bind address $LOCAL_IP..."
echo "Keep this terminal window open while using the application."
echo

# Kill any existing tunnels
pkill -f "minikube tunnel" >/dev/null 2>&1 || true

echo "==========================================================
Setup complete! Starting tunnel in 3 seconds...
Your app will be accessible at: http://$DOMAIN/

Remember:
1. This terminal must remain open while using the application
2. You may need to flush DNS cache:
   - macOS: sudo killall -HUP mDNSResponder
   - Linux: sudo systemd-resolve --flush-caches or sudo resolvectl flush-caches
3. Try restarting your browser if the site doesn't load
=========================================================="

sleep 3
minikube tunnel --bind-address="$LOCAL_IP"