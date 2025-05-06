This repository contains a full-stack application with:

- FastAPI backend with PostgreSQL database
- React/TypeScript frontend
- Kubernetes Helm charts


## Kubernetes Deployment - The Fun Part! 🚢

Ready to sail your app into Kubernetes waters? Let's do this! 🎯

### 1. Starting Your Minikube Adventure
```bash
# Fire up your very own Kubernetes cluster
minikube start

# Check if your ship is ready to sail
minikube status
```

### 2. Setting Up Ingress - The Gateway to Your App 🌉

Minikube's ingress addon is your best friend for local access:

```bash
# Enable the magical ingress powers
minikube addons enable ingress

# Verify it's ready
kubectl get pods -n ingress-nginx
```

### 3. The Secret Sauce: Connecting Your Local Machine 🔌

Here's where the magic happens! To access your app locally:

```bash
# Find your network interface IP
# On Windows:
ipconfig

# On Linux/macOS:
ifconfig
# or
ip addr show

# Look for your active connection (likely Wi-Fi or Ethernet)
# and note the IPv4 Address (e.g., 192.168.2.18)
```

### 4. Make Your Computer Talk to Minikube 🗣️

#### Windows Users

Create a script called `setup-minikube-access.bat` with these commands (or use the one provided in this repo):

Run this as administrator, and boom! Your computer and Minikube are now best buddies.

#### Linux/macOS Users

Create a script called `setup-minikube-access.sh` with these commands (or use the one provided in this repo):

Your computer and Minikube will become best buddies, Linux/macOS style!

### 5. Deploy Your Application 🚀

```bash
# Deploy the full stack with Helm
helm install devops-assignment charts/umbrella

# Watch your pods come to life
kubectl get pods -n devops-task -w
```

### 6. Access Your Application 🌐

Once everything is running, visit:
- Frontend: http://1ex.hire.roie.local/
- API: http://1ex.hire.roie.local/api/

## API Playground - Let's Talk to Our Backend! 🎮

Here are some examples to interact with the API:

### Creating a User (POST)
```bash
curl -X POST http://1ex.hire.roie.local/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"cool_user","email":"user@example.com"}'
```

Or if you prefer using your browser, try this in the console:
```javascript
fetch('/api/users', {
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

1. Open http://1ex.hire.roie.local/ in your browser
2. Create a new user through the form
3. See it appear in the users list
4. Check the API directly: http://1ex.hire.roie.local/api/users

If all of these steps work, congratulations! Your deployment is fully functional! 🎉

## CI/CD Pipeline - Automate All the Things! 🤖

This project includes a CI/CD pipeline that handles:

1. Building the application images
2. Running tests
3. Loading images to Minikube
4. Deploying to Kubernetes

To run the pipeline:

```bash
# Set up your environment variables (if needed for external registries)
export DOCKER_USERNAME=your-username
export DOCKER_PASSWORD=your-password

# For local pipeline testing with Minikube, you can use:
make build-images      # Build Docker images locally
make load-images       # Build and load images into Minikube
make update-helm       # Update Helm dependencies
make deploy-minikube   # Deploy to Minikube using local images
make minikube-cd       # Full CD process for Minikube

# For development:
make dev               # Run both frontend and backend in development mode
make frontend          # Run just frontend in development mode
make backend           # Run just backend in development mode
make test              # Run frontend and backend tests
```

### Monitoring Your Deployment

```bash
# Check that all pods are happy
kubectl get pods -n devops-task

# View the logs of the frontend
kubectl logs -n devops-task -l app=frontend

# View the logs of the backend
kubectl logs -n devops-task -l app=backend
```

Now you're a DevOps pro! 🏆 Happy deploying!
