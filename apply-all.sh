#!/bin/bash
# Deploy all services to k3s
set -e

echo "=== Deploy Forgejo ==="
kubectl apply -f forgejo/

echo "=== Deploy Monitoring Stack ==="
kubectl apply -f monitoring/

echo "=== Deploy Hello-Devops ==="
kubectl apply -f hello-devops/

echo ""
echo "=== Status ==="
kubectl get pods -n forgejo
kubectl get pods -n monitoring

echo ""
echo "=== Ingress ==="
kubectl get ingress -A

echo ""
echo "Service URLs:"
echo "  Forgejo:     http://git.localhost/"
echo "  Grafana:     http://grafana.localhost/"
echo "  Prometheus:  http://prometheus.localhost/"
echo "  Uptime Kuma: http://monitor.localhost/"
echo "  Hello:       http://hello.localhost/"
