# 1ex DevOps Assignment

This repository contains a full-stack application with:

- FastAPI backend with PostgreSQL database
- React/TypeScript frontend
- Kubernetes Helm charts

## Development

### Prerequisites
- Docker and Docker Compose
- Bun (for frontend)
- Python 3.12+
- Minikube for local Kubernetes deployment

### Running locally with Docker Compose
```bash
docker-compose up
```

### Running locally for development
```bash
# Start both frontend and backend
make dev

# Or start individually
make frontend
make backend
```

### Testing
```bash
make test
```

## Kubernetes Deployment
The application can be deployed to Kubernetes using Helm charts.

```bash
# Start Minikube
minikube start

# Deploy with Helm
helm install app charts/umbrella
```
