# k3s-infra

Manifests untuk k3s cluster di VPS (`1.2.3.4`). Semua service menggunakan Let's Encrypt SSL via Traefik.

## Struktur

```
k3s-infra/
├── namespaces.yaml             # Definisi Namespace K8s
├── traefik/                    # Traefik Ingress Controller + ACME
│   ├── traefik-deployment.yaml
│   ├── traefik-service.yaml
│   ├── traefik-config.yaml
│   ├── traefik-clusterrole.yaml
│   ├── traefik-clusterrolebinding.yaml
│   ├── traefik-ingressclass.yaml
│   └── traefik-pvc.yaml
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
│   └── deployer-rolebinding.yaml
├── kustomization.yaml          # Kustomize entrypoint
├── domains.env.example         # Template domain
├── forgejo-secrets.env.example # Template rahasia untuk Forgejo
├── traefik-secrets.env.example # Template rahasia untuk Traefik
├── grafana-secrets.env.example # Template rahasia untuk Grafana
├── runner-secrets.env.example  # Template rahasia untuk Runner
├── apply-all.sh
├── backup.sh                   # Backup K3s state, PV, & konfigurasi
├── restore.sh                  # Restore K3s di VPS baru (auto-install k3s)
└── README.md
```

## Security & Hardening
Infrastruktur ini telah diamankan dan dioptimasi:
- **Least Privilege RBAC**: Traefik dan Runner memiliki `ServiceAccount` khusus dengan hak akses terbatas.
- **NetworkPolicy**: Membatasi akses masuk ke pod aplikasi.
- **RunAsNonRoot**: Pod dijalankan tanpa akses root.
- **Portable PVC**: PVC tidak terikat pada cluster tertentu.
- **Modular Secrets**: Secret dipisah per service untuk meminimalkan dampak kebocoran kredensial.
- **Resource Constraints**: Disesuaikan untuk berjalan pada server (e.g., 2vCPU / 4GB RAM).

## Service URLs

| Service | URL | Akses |
|---------|-----|-------|
| Forgejo | `https://git.example.com/` | Publik |
| Grafana | `http://monitoring-grafana` (atau IP Tailscale) | Privat (Tailscale VPN) |
| Prometheus | `http://prometheus.monitoring.svc.cluster.local:9090` | Internal Cluster |
| Uptime Kuma | `http://monitoring-uptime-kuma` (atau IP Tailscale) | Privat (Tailscale VPN) |
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
cp forgejo-secrets.env.example forgejo-secrets.env
cp traefik-secrets.env.example traefik-secrets.env
cp grafana-secrets.env.example grafana-secrets.env
cp runner-secrets.env.example runner-secrets.env
# Edit file domains.env dan semua file *-secrets.env
```

Kemudian jalankan skrip berikut (menggunakan Kustomize):
```bash
./apply-all.sh
```

Atau jika ingin melihat hasil *render* YAML-nya tanpa men-deploy:
```bash
kubectl kustomize .
```

## Backup & Restore

### Backup (di VPS)
Menyimpan state SQLite K3s, kredensial cluster (`tls`, `cred`, `token`), seluruh PV aplikasi (termasuk snapshot konsisten SQLite seperti `kuma.db`), serta manifest & file `*.env` ke `~/k3s-backups/`:
```bash
sudo ./backup.sh
```
Salin hasil backup ke komputer lokal (off-site) agar aman jika VPS dihapus:
```bash
scp vps:~/k3s-backups/k3s-full-backup-*.tar.gz ~/backups/
```

### Restore (di VPS Ubuntu Baru)
`restore.sh` otomatis menginstall `sqlite3`, `curl`, dan `k3s` jika belum terpasang, memulihkan database, PV, serta `config/` + `~/.kube/config`:
```bash
sudo ./restore.sh ~/k3s-full-backup-TANGGAL.tar.gz
```
> Jika VPS baru memiliki IP publik baru, perbarui DNS record domain publik Anda ke IP baru tersebut dan pastikan Tailscale di host sudah aktif (`tailscale up`).

## CI/CD

Push ke `main` branch → auto test → build container → push registry → deploy k3s.
