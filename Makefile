.PHONY: dev frontend backend test deploy-minikube build-images load-images update-helm

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

# Deploy to Minikube
deploy-minikube: load-images update-helm
	helm upgrade --install umbrella ./charts/umbrella \
	  --set backend.image.repository=localhost:5000/backend \
	  --set backend.image.tag=latest \
	  --set backend.image.pullPolicy=Never \
	  --set frontend.image.repository=localhost:5000/frontend \
	  --set frontend.image.tag=latest \
	  --set frontend.image.pullPolicy=Never \
	  --set global.domain=minikube.local \
	  --set global.environment=development

# Full CD process for Minikube
minikube-cd: deploy-minikube
	@echo "Application deployed to Minikube!"
	@echo "Access the application at http://minikube.local/ (make sure minikube.local is in your hosts file)"
	@echo "To start the tunnel if needed, run: minikube tunnel"
