# k3s-monitoring

Manifests untuk deployment monitoring stack di k3s laptop. Semua service diakses via `.localhost` (resolve otomatis).

## Struktur

```
k3s-monitoring/
├── forgejo/           # Forgejo Git Server
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
│   └── ingress.yaml
├── hello-devops/      # Sample App
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── apply-all.sh       # Deploy semua service
└── README.md
```

## Service URLs

| Service | URL |
|---------|-----|
| Forgejo | `http://git.localhost/` |
| Grafana | `http://grafana.localhost/` (admin/admin) |
| Prometheus | `http://prometheus.localhost/` |
| Uptime Kuma | `http://monitor.localhost/` |
| hello-devops | `http://hello.localhost/` |

## Deploy Semua

```bash
./apply-all.sh
```

## Deploy Per-Service

```bash
kubectl apply -f forgejo/
kubectl apply -f monitoring/
kubectl apply -f hello-devops/
```
