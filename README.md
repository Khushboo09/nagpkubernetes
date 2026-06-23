# Kubernetes, DevOps & FinOps Microservices NAGP Assignment

This project demonstrates a multi-tier application architecture deployed on Kubernetes, featuring a Spring Boot REST API service backed by a MySQL database. The implementation showcases core Kubernetes concepts including service discovery, configuration management, persistent storage, horizontal pod autoscaling, and FinOps best practices.

## Architecture Overview

The system implements a two-tier architecture:
- **API Service Tier**: Spring Boot REST API exposing student data endpoints
- **Database Tier**: MySQL database with persistent volume for data storage

Both tiers are containerized using Docker and orchestrated on Google Kubernetes Engine (GKE).

## Technology Stack

- **Backend**: Java, Spring Boot 
- **Database**: MySQL 
- **Containerization**: Docker
- **Orchestration**: Kubernetes (Google Kubernetes Engine)
- **Build Tool**: Maven
- **Container Registry**: Docker Hub

## Docker Image

The Spring Boot application has been containerized and published to Docker Hub for deployment:

**Code Repository**: [https://github.com/Khushboo09/nagpkubernetes](https://github.com/Khushboo09/nagpkubernetes)
**Docker Hub Repository**: [khushboo091991/studentservice](https://hub.docker.com/r/khushboo091991/studentservice)  
**Image Tag**: `khushboo091991/studentservice:0.0.1`
**Image Tag**: `khushboo091991/studentservice:0.0.2`

**Service API URL Example**: `http://<INGRESS-IP>/students`

## Project Structure

```
├── student-rest_service/           # Spring Boot application source code
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/student/   # Java source files
│   │   │   └── resources/          # Application properties
│   ├── Dockerfile                  # Docker image configuration
│   └── pom.xml                     # Maven dependencies
├── Yaml Files/                     # Kubernetes manifests
│   ├── db-deployment.yaml          # MySQL deployment with PVC
│   ├── mysql-configMap.yaml        # Database configuration
│   ├── mysql-secrets.yaml          # Database credentials
│   ├── student-service-deployment.yaml  # API service deployment
│   ├── student-service-hpa.yaml    # Horizontal Pod Autoscaler
│   └── student-service-ingress.yaml     # Ingress configuration
└── student_db.sql                  # Database initialization script
```

## API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/students` | GET | Retrieves all student records | JSON array of student objects |
| `/students/health` | GET | Health check endpoint | `{healthy: true}` |

### Sample Response

```json
[
  {
    "id": 1,
    "studentName": "Rahul Sharma",
    "course": "Computer Science",
    "email": "rahul@gmail.com",
    "age": 21
  },
  {
    "id": 2,
    "studentName": "Priya Verma",
    "course": "Mechanical Engineering",
    "email": "priya@gmail.com",
    "age": 22
  }
]
```

## Kubernetes Implementation Details

### Service API Tier Configuration

| Feature | Implementation |
|---------|----------------|
| **Replicas** | 4 pods (scalable via HPA) |
| **Deployment Strategy** | RollingUpdate (maxSurge: 1, maxUnavailable: 0) |
| **Service Type** | ClusterIP (exposed via Ingress) |
| **External Access** | NGINX Ingress Controller |
| **ConfigMap** | Database host and name configuration |
| **Secrets** | Database password (base64 encoded) |
| **Resource Limits** | CPU: 100m-1000m, Memory: 128Mi-256Mi |
| **HPA** | Min: 4, Max: 8 pods (80% CPU/Memory threshold) |

### Database Tier Configuration

| Feature | Implementation |
|---------|----------------|
| **Replicas** | 1 pod (StatefulSet pattern) |
| **Deployment Strategy** | Recreate |
| **Service Type** | ClusterIP (headless service) |
| **Persistent Volume** | 100Mi PVC with ReadWriteOnce access |
| **Access Scope** | Cluster-internal only |
| **Resource Limits** | CPU: 250m-1000m, Memory: 512Mi-1Gi |
| **Data Persistence** | Volume mounted at `/var/lib/mysql` |

## FinOps Considerations

This deployment implements several cost optimization strategies:

### 1. **Resource Right-Sizing**
- API Service: Conservative limits (100m CPU, 128Mi RAM requests) with headroom for bursts
- Database: Appropriate limits (250m CPU, 512Mi RAM) based on workload characteristics
- Prevents over-provisioning and reduces cloud costs

### 2. **Horizontal Pod Autoscaling**
- Dynamic scaling between 4-8 pods based on actual demand (CPU/Memory at 80%)
- Scales down during low traffic with 5-minute stabilization window
- Eliminates paying for idle capacity

### 3. **Efficient Storage Allocation**
- Minimal PVC size (100Mi) suitable for development/demo workloads
- Can be adjusted based on actual data growth patterns
- Avoids over-provisioning expensive persistent storage

### 4. **Cost Optimization Opportunities**
- **Node Affinity**: Leverage spot/preemptible instances for non-critical environments
- **Cluster Autoscaling**: Enable GKE cluster autoscaler to optimize node pool size
- **Pod Disruption Budgets**: Ensure safe scaling operations without over-provisioning
- **Resource Quotas**: Implement namespace-level quotas to prevent cost overruns
- **Monitoring**: Use GKE cost allocation and recommendations for continuous optimization

## Prerequisites

- Google Cloud Platform account with billing enabled
- GKE cluster provisioned 
- `kubectl` CLI installed and configured
- `gcloud` CLI authenticated
- NGINX Ingress Controller installed on cluster

## Deployment Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/Khushboo09/nagpkubernetes.git
cd nagpkubernetes
```

### Step 2: Connect to GKE Cluster

```bash
gcloud container clusters get-credentials <cluster-name> --zone <zone> --project <project-id>
```

### Step 3: Deploy Database Tier

Navigate to the Kubernetes manifests directory:

```bash
cd "Yaml Files"
```

Apply the database configuration in sequence:

```bash
# Create database secrets
kubectl apply -f mysql-secrets.yaml

# Create database configuration
kubectl apply -f mysql-configMap.yaml

# Deploy MySQL with persistent storage
kubectl apply -f db-deployment.yaml
```

Verify the database pod is running:

```bash
kubectl get pods -l app=mysql
```

### Step 4: Initialize Database Schema

Once the MySQL pod is running, execute the initialization script:

```bash
# Get the MySQL pod name
export MYSQL_POD=$(kubectl get pod -l app=mysql -o jsonpath="{.items[0].metadata.name}")

# Copy the SQL script to the pod
kubectl cp ../student_db.sql $MYSQL_POD:/tmp/student_db.sql

# Execute the SQL script
kubectl exec -it $MYSQL_POD -- mysql -uroot -proot < /tmp/student_db.sql
```

Alternatively, manually create the schema:

```bash
kubectl exec -it $MYSQL_POD -- mysql -uroot -proot

# Then run:
CREATE SCHEMA IF NOT EXISTS student_db;
USE student_db;

CREATE TABLE students (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_name VARCHAR(100) NOT NULL,
    course VARCHAR(100),
    email VARCHAR(100),
    age INT,
    PRIMARY KEY (id)
);

INSERT INTO students (student_name, course, email, age) VALUES
('Rahul Sharma', 'Computer Science', 'rahul@gmail.com', 21),
('Priya Verma', 'Mechanical Engineering', 'priya@gmail.com', 22),
('Amit Kumar', 'Electronics', 'amit@gmail.com', 20),
('Sneha Gupta', 'Information Technology', 'sneha@gmail.com', 23),
('Vikas Singh', 'Civil Engineering', 'vikas@gmail.com', 21);
```

### Step 5: Deploy API Service

```bash
# Deploy the student service (4 replicas with rolling update)
kubectl apply -f student-service-deployment.yaml

# Configure Horizontal Pod Autoscaler
kubectl apply -f student-service-hpa.yaml

# Expose service via Ingress
kubectl apply -f student-service-ingress.yaml
```

### Step 6: Verify Deployment

Check all resources are running:

```bash
# View all pods
kubectl get pods

# View services
kubectl get svc

# View persistent volume claims
kubectl get pvc

# View HPA status
kubectl get hpa

# View Ingress
kubectl get ingress
```

Expected output should show:
- 4 student-service pods in Running state
- 1 MySQL pod in Running state
- PVC bound to a persistent volume
- HPA configured with current metrics
- Ingress with an assigned IP address

## Testing the Application

### Option 1: Via Ingress (External Access)

Get the Ingress IP address:

```bash
kubectl get ingress student-service-ingress
```

Access the API using the Ingress IP:

```bash
curl http://<INGRESS-IP>/students
```

### Option 2: Via Port Forwarding

Forward a local port to the service:

```bash
kubectl port-forward svc/student-service-mysql 9000:9000
```

Access the API locally:

```bash
curl http://localhost:9000/students
```

### Option 3: Via Browser

Open in browser: `http://<INGRESS-IP>/students`

## Demonstration Scenarios

### 1. Self-Healing - API Service

Delete a student service pod and observe automatic recreation:

```bash
# List current pods
kubectl get pods -l app=student-service-mysql

# Delete one pod
kubectl delete pod <student-service-pod-name>

# Immediately check again - you'll see the pod terminating and a new one creating
kubectl get pods -l app=student-service-mysql -w
```

**Result**: Kubernetes automatically recreates the pod to maintain the desired replica count of 4.

### 2. Self-Healing - Database with Data Persistence

Delete the MySQL pod and verify data persists:

```bash
# Query data before deletion
curl http://<INGRESS-IP>/students

# Delete MySQL pod
kubectl delete pod <mysql-pod-name>

# Wait for pod to recreate
kubectl get pods -l app=mysql -w

# Query data again - same records should be returned
curl http://<INGRESS-IP>/students
```

**Result**: The pod recreates automatically, and all student records remain intact due to persistent volume.

### 3. Rolling Update

Update the application image to trigger a rolling deployment:

```bash
# Update the deployment with a new image version
kubectl set image deployment/student-service-mysql student-service=khushboo091991/studentservice:0.0.2

# Watch the rolling update process
kubectl rollout status deployment/student-service-mysql
```

**Result**: Old pods are gradually replaced with new ones (one at a time) with zero downtime due to `maxUnavailable: 0`.

### 4. Horizontal Pod Autoscaling

Generate load to trigger autoscaling:

```bash
# Generate traffic using a load testing tool
kubectl run -it --rm load-generator --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://student-service-mysql:9000/students; done"

# In another terminal, watch HPA scaling
kubectl get hpa student-service-hpa -w
```

**Result**: When CPU/Memory exceeds 80%, HPA scales up to a maximum of 8 pods. After load stops, it scales down after 5-minute stabilization period.

### 5. Configuration Management

Verify database configuration is externalized:

```bash
# View ConfigMap
kubectl get configmap db-config -o yaml

# View Secret (base64 encoded)
kubectl get secret mysql-secrets -o yaml
```

**Result**: Database host, name, and credentials are managed outside application code.

## Clean Up

To avoid incurring charges, delete all resources:

```bash
kubectl delete -f student-service-ingress.yaml
kubectl delete -f student-service-hpa.yaml
kubectl delete -f student-service-deployment.yaml
kubectl delete -f db-deployment.yaml
kubectl delete -f mysql-configMap.yaml
kubectl delete -f mysql-secrets.yaml
```

Or delete the entire namespace (if using a dedicated namespace):

```bash
kubectl delete namespace <your-namespace>
```

## Key Learnings and Best Practices

1. **Never hardcode credentials**: Use Kubernetes Secrets for sensitive data
2. **Externalize configuration**: Use ConfigMaps for environment-specific settings
3. **Implement health checks**: Liveness and readiness probes ensure reliability
4. **Use rolling updates**: Zero-downtime deployments for continuous availability
5. **Right-size resources**: Define appropriate requests/limits to optimize costs
6. **Enable autoscaling**: HPA adapts capacity to actual demand
7. **Persist critical data**: Use PersistentVolumes for stateful workloads
8. **Service discovery**: Use DNS names (service names) instead of pod IPs
9. **Ingress for external access**: Centralized entry point with path-based routing
10. **Monitor and optimize**: Continuously review resource utilization for cost savings
