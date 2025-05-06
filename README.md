This repository contains a full-stack application with:

- FastAPI backend with PostgreSQL database
- React/TypeScript frontend
- Kubernetes Helm charts


## Kubernetes Deployment - The Fun Part! 🚢

Ready to sail your app into Kubernetes waters? Let's do this! 🎯

### 1. Starting Your Minikube Adventure
```bash
# Fire up your very own Kubernetes cluster (if not already running)
minikube start

# Check if your ship is ready to sail
minikube status
```

### 2. One-Step Setup (Requires Admin/sudo) 🛠️

We've simplified the setup! Run the following command. It will:
- Check if Minikube is running and start it if needed.
- Ensure the Ingress addon is enabled.
- Get the Minikube IP and your local network IP.
- **Update your hosts file** (requires Admin/sudo privileges) with entries for:
    - `minikube.local` (pointing to Minikube IP)
    - `1ex.hire.roie.local` (pointing to your local network IP)
- Provide instructions for the next step (running the tunnel).

```bash
# Run the combined setup script via Make
make setup
```

**Note:** This command detects your OS (Windows/Linux/macOS) and runs the appropriate script (`scripts/setup-windows.bat` or `scripts/setup-linux-macos.sh`). You will likely be prompted for your administrator/sudo password to modify the hosts file.

### 3. The Tunnel: Connecting Your Network 🔌

To access the application from other devices on your local network (using `http://1ex.hire.roie.local/`), you need to run the Minikube tunnel bound to your local IP address. The `make setup` command will tell you the exact command to run, which looks like this:

```bash
# Run this in a SEPARATE terminal and keep it running!
# Replace <YOUR_LOCAL_IP> with the IP detected/entered during 'make setup'
minikube tunnel --bind-address=<YOUR_LOCAL_IP>
```

### 4. Deploy Your Application 🚀

```bash
# Build images, load them into Minikube, and deploy via Helm
make minikube-cd

# Or, if you only want to deploy (assuming images are loaded):
# make deploy-minikube

# Watch your pods come to life
kubectl get pods -w
```

### 5. Access Your Application 🌐

Once the deployment is complete and the tunnel (if needed for network access) is running:

- **From your machine only:** http://minikube.local/
- **From any device on your local network:** http://1ex.hire.roie.local/

## API Playground - Let's Talk to Our Backend! 🎮

Here are some examples to interact with the API (use `minikube.local` or `1ex.hire.roie.local` depending on how you are accessing it):

### Creating a User (POST)
```bash
curl -X POST http://1ex.hire.roie.local/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"cool_user","email":"user@example.com"}'
```

Or if you prefer using your browser console:
```javascript
// Replace the domain if accessing via local network IP
fetch('http://minikube.local/api/users', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'cool_user', email: 'user@example.com' })
}).then(res => res.json()).then(console.log)
```

### Getting All Users (GET)
```bash
curl http://1ex.hire.roie.local/api/users
```

Browser console:
```javascript
fetch('/api/users').then(res => res.json()).then(console.log)
```

## Testing the Full Flow 🧪

Want to make sure everything is working? Try this testing flow:

1. Run `make setup` (if you haven't already).
2. Run `make minikube-cd`.
3. If accessing from other devices, start the `minikube tunnel --bind-address...` command in a separate terminal.
4. Open http://minikube.local/ or http://1ex.hire.roie.local/ in your browser.
5. Create a new user through the form.
6. See it appear in the users list.
7. Check the API directly: http://minikube.local/api/users or http://1ex.hire.roie.local/api/users

If all of these steps work, congratulations! Your deployment is fully functional! 🎉

## CI/CD Pipeline - Automate All the Things! 🤖

This project includes Make targets for common tasks:

```bash
# Run frontend and backend in development mode (hot-reloading)
make dev

# Run just frontend in development mode
make frontend

# Run just backend in development mode
make backend

# Run frontend and backend tests
make test

# --- Kubernetes/Minikube Targets ---

# Perform initial setup (Minikube checks, ingress, hosts file updates)
# Requires Admin/sudo privileges!
make setup

# Build Docker images locally
make build-images

# Build and load images into Minikube
make load-images

# Update Helm dependencies (run if you modify charts/umbrella/Chart.yaml)
make update-helm

# Deploy to Minikube using images already loaded
make deploy-minikube

# Full Build & Deploy process for Minikube (runs setup, load-images, update-helm, deploy-minikube)
make minikube-cd

```

### Monitoring Your Deployment

```bash
# Check that all pods are happy
kubectl get pods

# View the logs of the frontend
kubectl logs -l app=frontend

# View the logs of the backend
kubectl logs -l app=backend
```

Now you're a DevOps pro! 🏆 Happy deploying!
