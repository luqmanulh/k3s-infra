#!/bin/bash
# Apply all k3s manifests
set -e

echo "=== Traefik ==="
kubectl apply -f traefik/traefik-config.yaml
kubectl apply -f traefik/traefik-deployment.yaml
kubectl apply -f traefik/traefik-service.yaml
kubectl apply -f traefik/traefik-ingressclass.yaml
kubectl apply -f traefik/traefik-clusterrole.yaml
kubectl apply -f traefik/traefik-clusterrolebinding.yaml

echo "=== Forgejo ==="
kubectl apply -f forgejo/pvc.yaml
kubectl apply -f forgejo/deployment.yaml
kubectl apply -f forgejo/service.yaml
kubectl apply -f forgejo/ingress.yaml
kubectl apply -f forgejo/ssh-tcp-ingress.yaml

echo "=== Monitoring ==="
kubectl apply -f monitoring/prometheus/prometheus-rbac.yaml
kubectl apply -f monitoring/prometheus/prometheus-config.yaml
kubectl apply -f monitoring/prometheus/prometheus-pvc.yaml
kubectl apply -f monitoring/prometheus/prometheus-deployment.yaml
kubectl apply -f monitoring/prometheus/prometheus-service.yaml
kubectl apply -f monitoring/prometheus/prometheus-ingress.yaml
kubectl apply -f monitoring/node-exporter/node-exporter.yaml
kubectl apply -f monitoring/node-exporter/node-exporter-service.yaml
kubectl apply -f monitoring/grafana/grafana-deployment.yaml
kubectl apply -f monitoring/grafana/grafana-service.yaml
kubectl apply -f monitoring/grafana/grafana-ingress.yaml
kubectl apply -f monitoring/uptime-kuma/uptime-kuma-pvc.yaml
kubectl apply -f monitoring/uptime-kuma/uptime-kuma-deployment.yaml
kubectl apply -f monitoring/uptime-kuma/uptime-kuma-service.yaml
kubectl apply -f monitoring/uptime-kuma/uptime-kuma-ingress.yaml

echo "=== Apps ==="
kubectl apply -f apps/hello-devops/hello-devops-deployment.yaml
kubectl apply -f apps/hello-devops/hello-devops-service.yaml
kubectl apply -f apps/hello-devops/hello-devops-ingress.yaml

echo "=== Runner ==="
kubectl apply -f runner/deployer-sa.yaml
kubectl apply -f runner/deployer-clusterrolebinding.yaml
kubectl apply -f runner/pvc.yaml
kubectl apply -f runner/kubeconfig-configmap.yaml
kubectl apply -f runner/deployment.yaml

echo "=== Done! ==="
