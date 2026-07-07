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
├── apps/
│   └── hello-devops/           # Sample App (CI/CD demo)
├── monitoring/
│   ├── grafana/                # Grafana Dashboard
│   ├── prometheus/             # Prometheus Metrics
│   ├── node-exporter/          # Node Metrics Exporter
│   └── uptime-kuma/            # Uptime Monitoring
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

Sebelum melakukan deploy, pastikan Anda menyalin file environment dan mengisinya dengan kredensial yang valid:
```bash
cp domains.env.example domains.env
cp secrets.env.example secrets.env
# Edit file domains.env dan secrets.env
```

Kemudian jalankan skrip berikut (menggunakan Kustomize):
```bash
./apply-all.sh
```

Atau jika ingin melihat hasil *render* YAML-nya tanpa men-deploy:
```bash
kubectl kustomize .
```

## CI/CD

Push ke `main` branch → auto test → build container → push registry → deploy k3s.
