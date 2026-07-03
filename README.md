# k3s-infra

Manifests untuk k3s cluster di VPS (`1.2.3.4`). Semua service menggunakan Let's Encrypt SSL via Traefik.

## Struktur

```
k3s-infra/
├── traefik/                    # Traefik Ingress Controller + ACME
│   ├── traefik-deployment.yaml
│   ├── traefik-service.yaml
│   ├── traefik-config.yaml
│   ├── traefik-clusterrole.yaml
│   ├── traefik-clusterrolebinding.yaml
│   └── traefik-ingressclass.yaml
├── forgejo/                    # Forgejo Git + Container Registry + SSH
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── pvc.yaml
│   └── ssh-tcp-ingress.yaml
├── monitoring/
│   ├── grafana/                # Grafana Dashboard
│   ├── prometheus/             # Prometheus Metrics
│   ├── node-exporter/          # Node Metrics Exporter
│   ├── uptime-kuma/            # Uptime Monitoring
│   └── hello-devops/           # Sample App (CI/CD demo)
├── runner/                     # Forgejo Actions Runner (DinD + kubectl)
│   ├── deployment.yaml
│   ├── pvc.yaml
│   ├── kubeconfig-configmap.yaml
│   ├── deployer-sa.yaml
│   └── deployer-clusterrolebinding.yaml
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

> Grafana login: `admin` / `ganti_password_anda`

## Deploy

```bash
# Semua service
./apply-all.sh

# Atau per-service
kubectl apply -f traefik/
kubectl apply -f forgejo/
kubectl apply -f monitoring/grafana/
kubectl apply -f monitoring/prometheus/
kubectl apply -f monitoring/node-exporter/
kubectl apply -f monitoring/uptime-kuma/
kubectl apply -f monitoring/hello-devops/
kubectl apply -f runner/
```

## CI/CD

Push ke `main` branch → auto test → build container → push registry → deploy k3s.
