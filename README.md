# k3s-infra

Manifests untuk deployment stack di k3s VPS (`1.2.3.4`). Semua service menggunakan Let's Encrypt SSL.

## Struktur

```
k3s-infra/
├── forgejo/           # Forgejo Git Server + Container Registry
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   └── secret.yaml
├── monitoring/        # Monitoring Stack
│   ├── grafana-deployment.yaml
│   ├── grafana-service.yaml
│   ├── prometheus-deployment.yaml
│   ├── prometheus-service.yaml
│   ├── uptime-kuma-deployment.yaml
│   ├── uptime-kuma-service.yaml
│   ├── node-exporter.yaml
│   ├── node-exporter-service.yaml
│   └── ingress.yaml
├── hello-devops/      # Sample App (CI/CD auto-deploy)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── runner/            # Forgejo Actions Runner (DinD + kubectl)
│   └── deployment.yaml
├── apply-all.sh
└── README.md
```

## Service URLs

| Service | URL |
|---------|-----|
| Forgejo | `https://git.example.com/` |
| Grafana | `https://grafana.example.com/` |
| Prometheus | `https://prometheus.example.com/` |
| Uptime Kuma | `https://monitor.example.com/` |
| hello-devops | `https://hello.example.com/` |

> ℹ️ Grafana default credentials: `admin` / `admin` (change on first login)

## Deploy

```bash
# Semua service
./apply-all.sh

# Atau per-service
kubectl apply -f forgejo/
kubectl apply -f monitoring/
kubectl apply -f hello-devops/
kubectl apply -f runner/
```

## Secrets

Credentials disimpan sebagai Kubernetes Secrets + Forgejo Actions Secrets. Jangan commit password dalam bentuk plaintext. Gunakan:

```bash
kubectl create secret generic <name> --from-literal=key=value
```

## CI/CD

Push ke `main` branch hello-devops → auto test → build → push registry → deploy k3s.
