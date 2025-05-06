#!/bin/bash
set -e

echo "======================================================="
echo " Combined Minikube Setup & Access (Linux/macOS)"
echo "======================================================="
echo

# Check for sudo privileges early
if [ "$(id -u)" -ne 0 ]; then
  echo "This script needs sudo privileges to modify /etc/hosts"
  echo "Please run with sudo: sudo $0"
  exit 1
fi

echo "--- Part 1: Basic Minikube Setup ---"
echo

# Check if Minikube is running
echo "Checking if Minikube is running..."
if ! minikube status &>/dev/null; then
  echo "Starting Minikube..."
  minikube start
else
  echo "Minikube is already running."
fi

# Enable ingress addon if not already enabled
echo "Checking ingress addon..."
if ! minikube addons list | grep "ingress.*enabled" &>/dev/null; then
  echo "Enabling ingress addon..."
  minikube addons enable ingress
else
  echo "Ingress addon is already enabled."
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Update hosts file for minikube.local
MINIKUBE_DOMAIN="minikube.local"
echo "Checking /etc/hosts for $MINIKUBE_DOMAIN..."
if grep -q "$MINIKUBE_DOMAIN" /etc/hosts; then
  echo "Entry for $MINIKUBE_DOMAIN exists. Updating..."
  # Use a temporary file for sed compatibility between GNU and BSD (macOS)
  sed -i.bak "s/^.*$MINIKUBE_DOMAIN.*$/$MINIKUBE_IP $MINIKUBE_DOMAIN/" /etc/hosts
else
  echo "Adding $MINIKUBE_DOMAIN to /etc/hosts..."
  echo "$MINIKUBE_IP $MINIKUBE_DOMAIN" >> /etc/hosts
fi
echo "Hosts file updated for $MINIKUBE_DOMAIN."

echo
echo "--- Part 2: Local Network Access Setup ---"
echo

echo "Detecting your active network interface IP..."
LOCAL_IP=""
# Try using 'ip route' (Linux)
if command -v ip > /dev/null; then
  LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
fi
# Try using 'ifconfig' (macOS/older Linux)
if [ -z "$LOCAL_IP" ] && command -v ifconfig > /dev/null; then
   # Try to find the default interface first on macOS
   DEFAULT_IFACE=$(route -n get default 2>/dev/null | grep 'interface:' | awk '{print $2}')
   if [ -n "$DEFAULT_IFACE" ]; then
       LOCAL_IP=$(ifconfig "$DEFAULT_IFACE" | grep 'inet ' | awk '{print $2}')
   else
       # Generic fallback: find first private IP
       LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -E '^(192\.168|10\.|172\.(1[6-9]|2[0-9]|3[0-1]))\.' | head -n 1)
   fi
fi

if [ -z "$LOCAL_IP" ]; then
  echo "Could not automatically detect your local IP."
  read -p "Please enter your local network IP address: " LOCAL_IP
  if [ -z "$LOCAL_IP" ]; then
      echo "IP Address cannot be empty. Exiting."
      exit 1
  fi
else
  echo "Detected IP: $LOCAL_IP"
  read -p "Use this IP? [Y/n]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    read -p "Please enter your local network IP address: " LOCAL_IP
    if [ -z "$LOCAL_IP" ]; then
        echo "IP Address cannot be empty. Exiting."
        exit 1
    fi
  fi
fi

echo
echo "Using Local Network IP: $LOCAL_IP"
echo

# Update hosts file for custom domain
ACCESS_DOMAIN="1ex.hire.roie.local"
echo "Setting up /etc/hosts for $ACCESS_DOMAIN..."
if grep -q "$ACCESS_DOMAIN" /etc/hosts; then
  echo "Entry for $ACCESS_DOMAIN exists. Updating..."
  sed -i.bak "s/^.*$ACCESS_DOMAIN.*$/$LOCAL_IP $ACCESS_DOMAIN/" /etc/hosts
else
  echo "Adding $ACCESS_DOMAIN to /etc/hosts..."
  echo "$LOCAL_IP $ACCESS_DOMAIN" >> /etc/hosts
fi
echo "Hosts file updated for $ACCESS_DOMAIN."

echo
echo "--- Part 3: Start Tunnel (Manual Step) ---"
echo
echo "To access the application from other devices on your network (using http://$ACCESS_DOMAIN/),"
echo "you MUST run the following command in a SEPARATE terminal and keep it running:"
echo
echo "  minikube tunnel --bind-address="$LOCAL_IP""
echo
echo "Make sure you use the IP address: $LOCAL_IP"
echo

echo "=========================================================="
echo "Setup Complete!"
echo
echo "- For basic access (from this machine only): http://$MINIKUBE_DOMAIN/"
echo "  (Requires 'minikube tunnel' if service type is LoadBalancer)"
echo
echo "- For access from your local network: http://$ACCESS_DOMAIN/"
echo "  (Requires the tunnel command above to be running)"
echo
echo "Remember:"
echo "1. You may need to flush DNS cache:"
echo "   - macOS: sudo killall -HUP mDNSResponder"
echo "   - Linux: sudo systemd-resolve --flush-caches or sudo resolvectl flush-caches (if applicable)"
echo "2. Try restarting your browser if a site doesn't load"
echo "=========================================================="
echo
