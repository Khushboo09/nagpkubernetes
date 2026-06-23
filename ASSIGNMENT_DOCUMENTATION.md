# Assignment Documentation

## Requirement Understanding

The assignment requires designing and deploying a containerized microservice application on Kubernetes. The solution should demonstrate how an application service and a database can be packaged, configured, deployed, exposed, scaled, and managed using Kubernetes resources.

The project implements a student information REST API backed by a MySQL database. The application exposes student data through HTTP endpoints and stores the data in a persistent relational database. The complete solution covers both the application layer and the database layer, which makes it suitable for demonstrating a real multi-tier deployment instead of only deploying a standalone container.

The main requirements understood from the implemented solution are:

1. Build a REST-based microservice that can serve student data.
2. Containerize the service so it can run consistently across environments.
3. Deploy the service on Kubernetes using deployment manifests.
4. Deploy MySQL as the backend database inside the Kubernetes cluster.
5. Keep database data persistent even if the database pod is recreated.
6. Use Kubernetes ConfigMaps and Secrets to separate configuration and credentials from application code.
7. Expose the application externally through an ingress resource.
8. Enable high availability for the application tier by running multiple replicas.
9. Support automatic scaling of the application tier based on CPU and memory utilization.
10. Define CPU and memory requests and limits to keep the deployment predictable and cost-aware.
11. Provide a repeatable deployment structure through YAML manifests.

The solution therefore focuses on Kubernetes fundamentals such as deployments, services, persistent volume claims, ingress, configuration management, secret management, rolling updates, and horizontal pod autoscaling.

## Assumptions

The following assumptions were considered while preparing and implementing the solution:

1. Google Kubernetes Engine is used as the Kubernetes platform, and an NGINX Ingress Controller is available in the cluster.
2. Docker Hub is used as the image registry for the Spring Boot application image.
3. The MySQL database runs inside the Kubernetes cluster for simplicity and to demonstrate Kubernetes storage concepts.
4. The database password is stored as a Kubernetes Secret and encoded in base64, as expected by Kubernetes Secret manifests.
5. The database schema and initial student records are created using the provided SQL script.
6. The service currently provides read-only access to student data through a GET endpoint.
7. The persistent volume is dynamically provisioned by the Kubernetes cluster when the persistent volume claim is applied.
8. Resource requests and limits are sized for a small workload and can be adjusted after observing real usage metrics.
9. The ingress exposes the `/students` path and forwards requests to the internal student service.
10. The HPA depends on metrics availability in the cluster, such as the Kubernetes Metrics Server.

## Solution Overview

The solution is built as a two-tier application. The first tier is a Spring Boot REST API named `student-service`, and the second tier is a MySQL database. Both tiers are containerized and deployed on Kubernetes.

### Application Layer

The application is a Java 11 Spring Boot service. It uses Spring Web to expose REST endpoints and Spring Data JPA to communicate with the database. The main API endpoint is:

```text
GET /students
```

This endpoint returns the list of student records from the MySQL database. A simple health endpoint is also provided:

```text
GET /students/health
```

The code follows a basic layered structure:

- Controller layer receives HTTP requests.
- Service layer contains the business method for retrieving student data.
- DAO layer uses Spring Data JPA to interact with the database.
- Model layer maps the `STUDENTS` database table to the `Student` entity.

The database connection is not hardcoded in the Java code. Instead, the application reads the database host, database name, username, and password from environment variables. This makes the same container image reusable across environments.

### Containerization

The Spring Boot service is packaged as a jar file and then copied into a Docker image. The Dockerfile uses the Eclipse Temurin Java 11 runtime image. The container exposes port `9000`, which matches the Spring Boot server port configured in the application properties.

The application image used in the Kubernetes manifest is:

```text
khushboo091991/studentservice:0.0.1
```

The README also mentions a newer image tag:

```text
khushboo091991/studentservice:0.0.2
```

This allows rolling update demonstrations by moving the deployment from one image version to another.

### Database Layer

The database tier uses MySQL 5.7. The deployment creates a MySQL pod and mounts persistent storage at:

```text
/var/lib/mysql
```

A persistent volume claim named `mysql-pv-claim` requests `100Mi` of storage with `ReadWriteOnce` access. This ensures that database data is not lost when the MySQL pod is deleted and recreated.

The database name is supplied through a ConfigMap, and the root password is supplied through a Secret. The SQL script creates the `student_db` schema, creates the `students` table, and inserts sample student records.

### Kubernetes Deployment

The Kubernetes manifests are organized under the `Yaml Files` directory. The important resources are:

- `mysql-configMap.yaml` for database host and database name configuration.
- `mysql-secrets.yaml` for database credentials.
- `db-deployment.yaml` for MySQL deployment, persistent volume claim, and internal MySQL service.
- `student-service-deployment.yaml` for the Spring Boot deployment and internal service.
- `student-service-hpa.yaml` for horizontal pod autoscaling.
- `student-service-ingress.yaml` for external HTTP access.

The student service deployment starts with 4 replicas. This gives the API layer better availability than a single-pod deployment. If one application pod fails, Kubernetes can continue serving requests through the remaining pods while recreating the failed pod.

The deployment strategy for the application is `RollingUpdate`, with `maxSurge: 1` and `maxUnavailable: 0`. This means Kubernetes can create one extra pod during an update and avoids taking existing pods down before replacements are ready. It supports application upgrades with minimal or no downtime.

The MySQL deployment uses the `Recreate` strategy. This is suitable for this assignment because the database uses persistent storage and should avoid multiple pods trying to use the same single-writer volume at the same time.

### Service Discovery and Access

Kubernetes Services are used for stable internal networking.

The MySQL service is named `mysql`, and this name is used as the database host through the ConfigMap. This allows the student service to connect to the database using Kubernetes DNS instead of depending on pod IP addresses.

The student service is exposed internally as a ClusterIP service on port `9000`. External access is handled through the ingress resource. The ingress listens for requests on the `/students` path and forwards them to the student service.

### Scaling and Availability

The application tier is configured with a Horizontal Pod Autoscaler. The HPA keeps a minimum of 4 replicas and can scale up to 8 replicas. Scaling decisions are based on CPU and memory utilization, both targeting 80 percent average utilization.

This configuration helps the application handle increased traffic without manually changing the deployment replica count. The scale-down behavior includes a stabilization window of 300 seconds, which helps avoid rapid scaling down immediately after a temporary traffic spike.

### Configuration and Security

The solution uses a ConfigMap for non-sensitive configuration values:

- Database host
- Database name

It uses a Secret for sensitive values:

- Database username
- Database password

This separation is important because configuration values often change between environments, and credentials should not be placed directly inside application source code or container images.

### Data Initialization

The `student_db.sql` file contains the schema and seed data for the application. It creates the database, creates the `students` table, and inserts sample records. This allows the API to return meaningful data after deployment.

## Justification for the Resources Utilized

### Spring Boot Application

Spring Boot is a good choice for the REST API because it provides a quick and reliable way to build production-style Java services. It includes embedded server support, REST controller support, dependency injection, configuration management, and easy database integration.

The application uses Spring Data JPA because the required database operation is straightforward: retrieving student records. Spring Data JPA reduces boilerplate code and allows the repository interface to provide common database operations without writing manual SQL queries in the service layer.

Java 11 is used because it is a stable long-term-support Java version and works well with the Spring Boot version used in the project.

### MySQL Database

MySQL is used because the student data is structured and fits naturally into a relational table. The data includes fields such as student id, name, course, email, and age. A relational database is appropriate for this kind of tabular data and can be queried reliably through JPA.

MySQL 5.7 is also simple to run as a container for an assignment environment. It keeps the deployment self-contained and demonstrates how a backend service connects to a database inside Kubernetes.

### Docker

Docker is used to package the Spring Boot service with its runtime requirements. Once the jar is built and copied into the image, the same image can be deployed consistently on any Kubernetes cluster. This avoids environment mismatch issues between local development and cluster deployment.

The Dockerfile uses a Java runtime image instead of a full build image because the application is already packaged before being copied into the container. This keeps the runtime image simpler.

### Kubernetes Deployment for Student Service

A Kubernetes Deployment is used for the student service because the API pods are stateless. Stateless application pods can be safely replicated, replaced, and updated by Kubernetes.

The deployment uses 4 replicas to improve availability. If one pod fails, other pods can still handle traffic. Kubernetes also recreates failed pods automatically to maintain the desired replica count.

The rolling update strategy is justified because application updates should not require downtime. With `maxUnavailable: 0`, Kubernetes avoids reducing the number of available pods during deployment. With `maxSurge: 1`, it can temporarily create one extra pod to help complete the update smoothly.

### Kubernetes Deployment for MySQL

The MySQL pod is deployed separately from the application because the database has a different lifecycle, storage requirement, and scaling pattern. It uses a single replica because the assignment focuses on persistence and connectivity rather than database clustering.

The `Recreate` strategy is used for MySQL because the database volume is mounted with `ReadWriteOnce`. This avoids the risk of multiple MySQL pods trying to write to the same storage volume at the same time.

### Persistent Volume Claim

The persistent volume claim is required because database data must survive pod restarts and pod recreation. Without persistent storage, deleting the MySQL pod would delete the data stored inside the container filesystem.

The requested storage size is `100Mi`, which is enough for assignment sample data and avoids unnecessary storage allocation. In a real production environment, this value would be decided based on expected data size, growth rate, backup strategy, and performance requirements.

### Kubernetes Services

Services are used because pod IPs are temporary. When pods restart, their IP addresses can change. A Kubernetes Service gives a stable DNS name and stable access point for pods.

The MySQL service allows the Spring Boot application to connect to the database using the service name `mysql`. The student service ClusterIP exposes the application inside the cluster and acts as the backend target for ingress.

ClusterIP is appropriate because neither MySQL nor the student service pods need to be exposed directly through public node ports. The database should remain internal, and the application should be exposed through ingress.

### ConfigMap

The ConfigMap stores non-sensitive database configuration such as host and database name. This is justified because these values can change between environments. For example, the database host might be different in local, development, staging, and production environments.

Using a ConfigMap avoids rebuilding the application image for simple configuration changes.

### Secret

The Secret stores database credentials. Credentials should not be hardcoded in Java code, Docker images, or plain application properties. Kubernetes Secrets provide a standard way to inject sensitive values into containers as environment variables.

Although Kubernetes Secrets are base64 encoded and not encrypted by default unless cluster encryption is enabled, using a Secret is still a better practice than storing credentials directly in source code.

### Horizontal Pod Autoscaler

The HPA is used to make the application tier responsive to load. Instead of permanently running the maximum number of pods, the application starts with 4 replicas and can scale to 8 when CPU or memory utilization increases.

This supports both availability and cost awareness. The system can add capacity when needed and scale down after demand decreases. The 300-second scale-down stabilization window helps prevent unnecessary pod churn after short traffic spikes.

### Ingress

Ingress is used as the external entry point for the application. It exposes the `/students` path and routes traffic to the student service. This is cleaner than exposing the service directly as a NodePort or LoadBalancer because ingress provides centralized HTTP routing.

Using NGINX ingress also makes it easier to add future HTTP features such as host-based routing, TLS termination, and path-based routing if the project grows.

### Resource Requests and Limits

Resource requests and limits are defined for both the application and database containers. This is important because Kubernetes uses requests for scheduling and limits for controlling maximum resource usage.

For the student service, the request is `100m` CPU and `128Mi` memory, with limits of `1000m` CPU and `256Mi` memory. This gives the lightweight REST API enough guaranteed resources while still allowing limited bursts.

For MySQL, the request is `250m` CPU and `512Mi` memory, with limits of `1000m` CPU and `1Gi` memory. The database is given more memory than the API because databases generally need more memory for query execution, caching, and storage operations.

These values are suitable for a small assignment deployment. They also show FinOps awareness by avoiding unlimited containers and unnecessary over-provisioning.

### Docker Hub Image Registry

Docker Hub is used to host the application image so the Kubernetes cluster can pull it during deployment. This makes the deployment repeatable and avoids depending on local machine images.

Using versioned tags such as `0.0.1` and `0.0.2` also supports controlled rollout and rollback demonstrations.

## Final Summary

The project successfully demonstrates a Kubernetes-based deployment of a Spring Boot microservice backed by MySQL. It uses containerization, Kubernetes deployments, services, ingress, persistent storage, ConfigMaps, Secrets, resource limits, and autoscaling to satisfy the assignment objectives.

The design is intentionally simple but complete. It keeps the API stateless, keeps the database stateful with persistent storage, exposes only the required application endpoint, and uses Kubernetes-native resources to manage configuration, availability, scaling, and cost control.
