#!/bin/bash

PROMPT="khushbookochhar@IN-J5W2RX3R7D nagpkubernates-main5 %"

clear

echo "============================================"
echo "PART 1: Show All Deployed Kubernetes Objects"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get all,ingress,pvc,configmap,secret -n default"
kubectl get all,ingress,pvc,configmap,secret -n default
sleep 4

echo ""
echo "$PROMPT kubectl get pods -n default -o wide"
kubectl get pods -n default -o wide
sleep 2

echo ""
echo "$PROMPT kubectl get deployments -n default -o wide"
kubectl get deployments -n default -o wide
sleep 2

echo ""
echo "$PROMPT kubectl get svc -n default -o wide"
kubectl get svc -n default -o wide
sleep 2

echo ""
echo "$PROMPT kubectl get ingress -n default"
kubectl get ingress -n default
sleep 2

echo ""
echo "$PROMPT kubectl get configmap -n default"
kubectl get configmap -n default
sleep 2

echo ""
echo "$PROMPT kubectl describe configmap db-config -n default"
kubectl describe configmap db-config -n default
sleep 3

echo ""
echo "$PROMPT kubectl get secrets -n default"
kubectl get secrets -n default
sleep 2

echo ""
echo "$PROMPT kubectl describe secret mysql-secrets -n default"
kubectl describe secret mysql-secrets -n default
sleep 3

echo ""
echo "$PROMPT kubectl get pvc -n default"
kubectl get pvc -n default
sleep 2

echo ""
echo "$PROMPT kubectl describe pvc mysql-pv-claim -n default"
kubectl describe pvc mysql-pv-claim -n default
sleep 3

echo ""
echo "$PROMPT kubectl get pv"
kubectl get pv
sleep 2

echo ""
echo "$PROMPT kubectl get rs -n default"
kubectl get rs -n default
sleep 2

echo ""
echo "$PROMPT kubectl get hpa -n default"
kubectl get hpa -n default
sleep 2

echo ""
echo "============================================"
echo "PART 2: API Call - Retrieve Student Records"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get ingress -n default -o wide"
kubectl get ingress -n default -o wide
sleep 2

echo ""
echo "$PROMPT curl http://34.73.251.215/students"
curl http://34.73.251.215/students
sleep 3

echo ""
echo ""
echo "$PROMPT curl -s http://34.73.251.215/students | jq ."
curl -s http://34.73.251.215/students | jq .
sleep 4

echo ""
echo "============================================"
echo "PART 3: Self-Healing - Kill API Pod"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get pods -n default -l app=student-service-mysql"
kubectl get pods -n default -l app=student-service-mysql
sleep 2

echo ""
POD_NAME=$(kubectl get pods -n default -l app=student-service-mysql -o jsonpath='{.items[0].metadata.name}')
echo "$PROMPT kubectl delete pod $POD_NAME -n default"
kubectl delete pod $POD_NAME -n default
sleep 1

echo ""
echo "$PROMPT kubectl get pods -n default -l app=student-service-mysql -w"
kubectl get pods -n default -l app=student-service-mysql -w &
WATCH_PID=$!
sleep 10
kill $WATCH_PID 2>/dev/null
sleep 1

echo ""
echo "$PROMPT kubectl get pods -n default -l app=student-service-mysql"
kubectl get pods -n default -l app=student-service-mysql
sleep 2

echo ""
echo "$PROMPT curl -s http://34.73.251.215/students | jq 'length'"
curl -s http://34.73.251.215/students | jq 'length'
sleep 2

echo ""
echo "============================================"
echo "PART 4: Data Persistence - Kill Database Pod"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get pods -n default -l app=mysql"
kubectl get pods -n default -l app=mysql
sleep 2

echo ""
DB_POD=$(kubectl get pods -n default -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "$PROMPT kubectl exec -it $DB_POD -n default -- mysql -u root -proot -e \"USE student_db; SELECT * FROM students;\""
kubectl exec -it $DB_POD -n default -- mysql -u root -proot -e "USE student_db; SELECT * FROM students;" 2>/dev/null
sleep 3

echo ""
echo "$PROMPT kubectl delete pod $DB_POD -n default"
kubectl delete pod $DB_POD -n default
sleep 1

echo ""
echo "$PROMPT kubectl get pods -n default -l app=mysql -w"
kubectl get pods -n default -l app=mysql -w &
WATCH_PID=$!
sleep 12
kill $WATCH_PID 2>/dev/null
sleep 1

echo ""
echo "$PROMPT kubectl wait --for=condition=ready pod -l app=mysql -n default --timeout=60s"
kubectl wait --for=condition=ready pod -l app=mysql -n default --timeout=60s
sleep 2

echo ""
NEW_DB_POD=$(kubectl get pods -n default -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "$PROMPT kubectl exec -it $NEW_DB_POD -n default -- mysql -u root -proot -e \"USE student_db; SELECT * FROM students;\""
kubectl exec -it $NEW_DB_POD -n default -- mysql -u root -proot -e "USE student_db; SELECT * FROM students;" 2>/dev/null
sleep 3

echo ""
echo "$PROMPT kubectl get pvc mysql-pv-claim -n default"
kubectl get pvc mysql-pv-claim -n default
sleep 2

echo ""
echo "============================================"
echo "PART 5: Deployment Strategy"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl describe deployment student-service-mysql -n default | grep -A 10 \"Strategy\""
kubectl describe deployment student-service-mysql -n default | grep -A 10 "Strategy"
sleep 3

echo ""
echo "$PROMPT kubectl get deployment student-service-mysql -n default -o yaml | grep -A 5 \"strategy:\""
kubectl get deployment student-service-mysql -n default -o yaml | grep -A 5 "strategy:"
sleep 2

echo ""
echo "$PROMPT kubectl describe deployment mysql -n default | grep -A 5 \"Strategy\""
kubectl describe deployment mysql -n default | grep -A 5 "Strategy"
sleep 2

echo ""
echo "$PROMPT kubectl rollout restart deployment/student-service-mysql -n default"
kubectl rollout restart deployment/student-service-mysql -n default
sleep 1

echo ""
echo "$PROMPT kubectl rollout status deployment/student-service-mysql -n default"
kubectl rollout status deployment/student-service-mysql -n default
sleep 2

echo ""
echo "$PROMPT kubectl rollout history deployment/student-service-mysql -n default"
kubectl rollout history deployment/student-service-mysql -n default
sleep 2

echo ""
echo "============================================"
echo "PART 6: FinOps - Resource Management"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get deployment student-service-mysql -n default -o yaml | grep -A 10 \"resources:\""
kubectl get deployment student-service-mysql -n default -o yaml | grep -A 10 "resources:"
sleep 3

echo ""
echo "$PROMPT kubectl top pods -n default"
kubectl top pods -n default
sleep 2

echo ""
echo "$PROMPT kubectl top nodes"
kubectl top nodes
sleep 2

echo ""
echo "$PROMPT kubectl describe nodes | grep -A 5 \"Allocated resources\" | head -20"
kubectl describe nodes | grep -A 5 "Allocated resources" | head -20
sleep 3

echo ""
echo "$PROMPT cat \"Yaml Files/student-service-hpa.yaml\""
cat "Yaml Files/student-service-hpa.yaml"
sleep 3

echo ""
echo "============================================"
echo "PART 7: HPA - Horizontal Pod Autoscaler Demo"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl apply -f \"Yaml Files/student-service-hpa.yaml\""
kubectl apply -f "Yaml Files/student-service-hpa.yaml"
sleep 2

echo ""
echo "$PROMPT kubectl get hpa -n default"
kubectl get hpa -n default
sleep 2

echo ""
echo "$PROMPT # Generating load - 1000 concurrent requests"
for i in {1..1000}; do
  curl -s http://34.73.251.215/students > /dev/null &
done
sleep 3

echo ""
echo "$PROMPT kubectl get hpa -n default -w"
kubectl get hpa -n default -w &
WATCH_PID=$!
sleep 15
kill $WATCH_PID 2>/dev/null
sleep 1

echo ""
echo "$PROMPT kubectl get pods -n default -l app=student-service-mysql"
kubectl get pods -n default -l app=student-service-mysql
sleep 2

echo ""
echo "$PROMPT kubectl delete hpa student-service-hpa -n default"
kubectl delete hpa student-service-hpa -n default
sleep 1

echo ""
echo "$PROMPT kubectl scale deployment student-service-mysql --replicas=4 -n default"
kubectl scale deployment student-service-mysql --replicas=4 -n default
sleep 2

echo ""
echo "$PROMPT kubectl get pods -n default -l app=student-service-mysql"
kubectl get pods -n default -l app=student-service-mysql
sleep 2

echo ""
echo "============================================"
echo "FINAL SUMMARY - All Resources"
echo "============================================"
echo ""
sleep 2

echo "$PROMPT kubectl get deployments -n default"
kubectl get deployments -n default
sleep 2

echo ""
echo "$PROMPT kubectl get pods -n default"
kubectl get pods -n default
sleep 2

echo ""
echo "$PROMPT kubectl get svc -n default"
kubectl get svc -n default
sleep 2

echo ""
echo "$PROMPT kubectl get ingress -n default"
kubectl get ingress -n default
sleep 2

echo ""
echo "$PROMPT kubectl get pvc -n default"
kubectl get pvc -n default
sleep 2

echo ""
echo "$PROMPT kubectl get configmap,secret -n default"
kubectl get configmap,secret -n default
sleep 2

echo ""
echo "============================================"
echo "DEMONSTRATION COMPLETE!"
echo "============================================"
echo ""
