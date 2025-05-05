#!/bin/bash
# This script ensures Minikube is properly set up before deployment

set -e

echo "======================================================="
echo "      Setting up Minikube for local deployment"
echo "======================================================="
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

# Check if minikube.local is in /etc/hosts
if grep -q "minikube.local" /etc/hosts; then
  echo "Updating minikube.local entry in /etc/hosts..."
  sudo sed -i "/$MINIKUBE_IP/d" /etc/hosts
  echo "$MINIKUBE_IP minikube.local" | sudo tee -a /etc/hosts
else
  echo "Adding minikube.local entry to /etc/hosts..."
  echo "$MINIKUBE_IP minikube.local" | sudo tee -a /etc/hosts
fi

echo
echo "Minikube environment is ready!"
echo "You can now run 'make minikube-cd' to deploy the application."
echo