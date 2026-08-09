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
│   ├── deployer-sa.yaml
│   └── deployer-clusterrolebinding.yaml
├── kustomization.yaml            # Kustomize entrypoint
├── domains.env.example         # Template domain
├── secrets.env.example         # Template rahasia (password, token)
├── apply-all.sh
└── README.md
```

## Service URLs

| Service | URL | Akses |
|---------|-----|-------|
| Forgejo | `https://git.example.com/` | Publik |
| Grafana | Dibuat otomatis oleh Tailscale (mis: `https://grafana...ts.net/`) | Privat (Tailscale VPN) |
| Prometheus | `http://prometheus:9090` | Internal Cluster |
| Uptime Kuma | Dibuat otomatis oleh Tailscale (mis: `https://uptime...ts.net/`) | Privat (Tailscale VPN) |
| hello-devops | `https://hello.example.com/` | Publik |

## Prasyarat: Tailscale Operator (Keamanan Monitoring)

Dasbor pemantauan (Grafana & Uptime Kuma) tidak diekspos ke publik demi keamanan (*Zero-Trust*). Untuk mengaksesnya, instal **Tailscale Kubernetes Operator** di *cluster* Anda menggunakan Helm:

```bash
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
  --namespace tailscale --create-namespace \
  --set-string oauth.clientId="<YOUR_OAUTH_CLIENT_ID>" \
  --set-string oauth.clientSecret="<YOUR_OAUTH_CLIENT_SECRET>" \
  --wait
```
Tailscale otomatis membuatkan URL privat untuk Grafana dan Uptime Kuma berkat anotasi `tailscale.com/expose: "true"` pada *Service*.

## Deploy

Sebelum melakukan deploy aplikasi, pastikan Anda menyalin file environment dan mengisinya dengan kredensial yang valid:
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
