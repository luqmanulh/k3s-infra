#!/bin/bash
# Apply all k3s manifests using Kustomize
set -e

if [ ! -f domains.env ] || [ ! -f grafana-secrets.env ] || [ ! -f forgejo-secrets.env ] || [ ! -f runner-secrets.env ] || [ ! -f traefik-secrets.env ]; then
  # Automatically generate `.env` files for the first time if they don't exist
  if [ ! -f domains.env ]; then cp domains.env.example domains.env; fi
  if [ ! -f grafana-secrets.env ]; then cp grafana-secrets.env.example grafana-secrets.env; fi
  if [ ! -f forgejo-secrets.env ]; then cp forgejo-secrets.env.example forgejo-secrets.env; fi
  if [ ! -f runner-secrets.env ]; then cp runner-secrets.env.example runner-secrets.env; fi
  if [ ! -f traefik-secrets.env ]; then cp traefik-secrets.env.example traefik-secrets.env; fi
  echo "Warning: one or more env files created from template. Please configure them!"
fi

echo "Applying Kustomize to k3s cluster..."
kubectl apply -k .
echo "=== Done! ==="
