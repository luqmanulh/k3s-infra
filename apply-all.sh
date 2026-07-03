#!/bin/bash
# Apply all k3s manifests
set -e

echo "=== Traefik ==="
kubectl apply -f traefik-config.yaml
kubectl apply -f traefik-deployment.yaml
kubectl apply -f traefik-service.yaml
kubectl apply -f traefik-ingressclass.yaml
kubectl apply -f traefik-clusterrole.yaml
kubectl apply -f traefik-clusterrolebinding.yaml

echo "=== Forgejo ==="
kubectl apply -f forgejo/pvc.yaml
kubectl apply -f forgejo/deployment.yaml
kubectl apply -f forgejo/service.yaml
kubectl apply -f forgejo/ingress.yaml
kubectl apply -f forgejo/ssh-tcp-ingress.yaml

echo "=== Monitoring ==="
kubectl apply -f monitoring/prometheus-rbac.yaml
kubectl apply -f monitoring/prometheus-config.yaml
kubectl apply -f monitoring/prometheus-pvc.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml
kubectl apply -f monitoring/prometheus-service.yaml
kubectl apply -f monitoring/prometheus-ingress.yaml
kubectl apply -f monitoring/node-exporter.yaml
kubectl apply -f monitoring/node-exporter-service.yaml
kubectl apply -f monitoring/grafana-deployment.yaml
kubectl apply -f monitoring/grafana-service.yaml
kubectl apply -f monitoring/grafana-ingress.yaml
kubectl apply -f monitoring/uptime-kuma-pvc.yaml
kubectl apply -f monitoring/uptime-kuma-deployment.yaml
kubectl apply -f monitoring/uptime-kuma-service.yaml
kubectl apply -f monitoring/uptime-kuma-ingress.yaml
kubectl apply -f monitoring/hello-devops-deployment.yaml
kubectl apply -f monitoring/hello-devops-service.yaml
kubectl apply -f monitoring/hello-devops-ingress.yaml

echo "=== Runner ==="
kubectl apply -f runner/deployer-sa.yaml
kubectl apply -f runner/deployer-clusterrolebinding.yaml
kubectl apply -f runner/pvc.yaml
kubectl apply -f runner/kubeconfig-configmap.yaml
kubectl apply -f runner/deployment.yaml

echo "=== Done! ==="
