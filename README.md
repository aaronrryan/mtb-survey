# Mountain Biking Survey Application

A Kubernetes-deployed web application for collecting mountain biking experiences.

## Components
- Frontend: Nginx serving static HTML/CSS/JS
- Backend: Flask API
- Database: MySQL
- Infrastructure: Kubernetes with Terraform

## Architecture
- Ingress controller routes traffic to services
- Frontend service handles UI
- Flask API processes requests and stores data
- MySQL database for persistence
- MetalLB provides load balancing (IP: 192.168.1.45)

## Prerequisites
- Docker
- Kubernetes cluster
- Terraform
- kubectl configured
- MetalLB configured
- NGINX Ingress Controller

## Setup
1. Clone the repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars`
3. Update variables in `terraform.tfvars`
4. Build and push Docker images:
   ```bash
   docker build -t aaronrryan/mtb-survey-frontend:latest --build-arg APP_VERSION=1.0.0 .
   docker build -t aaronrryan/mtb-survey-api:latest -f Dockerfile.api .
   docker push aaronrryan/mtb-survey-frontend:latest
   docker push aaronrryan/mtb-survey-api:latest
   ```

5. Deploy with Terraform:
   ```bash
   terraform init
   terraform apply
   ```

6. Add to /etc/hosts:
   ```bash
   echo "192.168.1.45 mtb.local" | sudo tee -a /etc/hosts
   ```

## Access
- Frontend: http://mtb.local
- API Endpoints:
  - POST http://mtb.local/api/survey (Submit survey)
  - GET http://mtb.local/api/surveys (View results)

## Features
- Responsive mountain-themed UI
- Real-time survey submission
- Results view with submission timestamps
- Client IP tracking
- Version tracking

## Infrastructure
- Namespace: mtb-survey
- Services:
  - Frontend (ClusterIP)
  - API (ClusterIP)
  - MySQL (ClusterIP)
- Persistent storage for MySQL
- NGINX Ingress for routing

## Development
To update the application version:
1. Update `app_version` in terraform.tfvars
2. Rebuild and push Docker images
3. Apply Terraform changes

## Monitoring
Check deployment status:
```bash
kubectl get all -n mtb-survey
kubectl logs -f deployment/flask-api -n mtb-survey
```
