#!/bin/bash
# Apply all k3s manifests using Kustomize
set -e

if [ ! -f domains.env ] || [ ! -f secrets.env ]; then
  # Automatically generate `.env` files for the first time if they don't exist
  if [ ! -f domains.env ]; then cp domains.env.example domains.env; fi
  if [ ! -f secrets.env ]; then cp secrets.env.example secrets.env; fi
  echo "Warning: domains.env or secrets.env created from template. Please configure them!"
fi

echo "Applying Kustomize to k3s cluster..."
kubectl apply -k .
echo "=== Done! ==="
