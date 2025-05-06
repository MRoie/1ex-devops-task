.PHONY: dev frontend backend test deploy-minikube build-images load-images update-helm setup minikube-cd clean-old-scripts

# Default domain for local access
DOMAIN=1ex.hire.roie.local
# Domain for basic minikube setup
MINIKUBE_DOMAIN=minikube.local

frontend:
	cd frontend && bun run dev &
backend:
	cd backend && uvicorn app.main:app --reload &

dev: frontend backend

test:
	npm run test && pytest -q

# Build Docker images locally
build-images:
	docker build -t localhost:5000/frontend:latest ./frontend
	docker build -t localhost:5000/backend:latest ./backend

# Load images into Minikube
load-images: build-images
	minikube image load localhost:5000/frontend:latest
	minikube image load localhost:5000/backend:latest

# Update Helm dependencies
update-helm:
	cd charts/umbrella && helm dependency update

# --- Combined Minikube Setup & Access ---
# This script checks Minikube, ingress, updates hosts for both domains,
# and provides instructions for the tunnel. Requires Admin/sudo.
minikube-setup:
ifeq ($(OS),Windows_NT)
	@echo "Running combined Windows setup script (Requires Admin privileges)..."
	@cmd /c scripts\\minikube-setup-windows.bat
else
	@echo "Running combined Linux/macOS setup script (Requires sudo privileges)..."
	@echo "You may be prompted for your sudo password to update /etc/hosts."
	@sudo bash scripts/minikube-setup-linux-macos.sh
endif

# Deploy to Minikube (using minikube.local domain)
deploy-minikube: load-images update-helm
	helm upgrade --install umbrella ./charts/umbrella \
	  --set backend.image.repository=localhost:5000/backend \
	  --set backend.image.tag=latest \
	  --set backend.image.pullPolicy=Never \
	  --set frontend.image.repository=localhost:5000/frontend \
	  --set frontend.image.tag=latest \
	  --set frontend.image.pullPolicy=Never \
	  --set global.domain=$(MINIKUBE_DOMAIN) \
	  --set global.environment=development

# Full CD process for Minikube
minikube-cd: deploy-minikube
	@echo "Application deployed to Minikube!"
	@echo "Run 'make setup' first if you haven't configured Minikube and hosts files."
	@echo "Access the application at http://$(MINIKUBE_DOMAIN)/"
	@echo "For access from other devices on your network (http://$(DOMAIN)/), follow the tunnel instructions from 'make setup'."

