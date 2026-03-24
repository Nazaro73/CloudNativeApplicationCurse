# Monitoring & Observabilite

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          GRAFANA (:3000)                            │
│                    Visualisation & Dashboards                       │
└─────────────────────┬───────────────────────┬───────────────────────┘
                      │                       │
                      ▼                       ▼
┌─────────────────────────────┐   ┌───────────────────────────────────┐
│     PROMETHEUS (:9090)      │   │          LOKI (:3100)             │
│   Stockage des metriques    │   │     Stockage des logs             │
└─────────────┬───────────────┘   └───────────────┬───────────────────┘
              │                                   │
              │ scrape                            │ push
              ▼                                   │
┌─────────────────────────────┐   ┌───────────────▼───────────────────┐
│   BACKEND NESTJS (/metrics) │   │        PROMTAIL                   │
│   - http_requests_total     │   │   Collecte des logs Docker        │
│   - http_request_duration   │   │                                   │
│   - process_cpu_seconds     │   │                                   │
└─────────────────────────────┘   └───────────────────────────────────┘
```

## Composants

### Prometheus
- **Role** : Collecte et stockage des metriques au format time-series
- **Fonctionnement** : Scrape les endpoints `/metrics` a intervalles reguliers
- **Port** : 9090
- **Interface** : http://localhost:9090

### Grafana
- **Role** : Visualisation des donnees via dashboards
- **Fonctionnement** : Se connecte a Prometheus et Loki comme datasources
- **Port** : 3000
- **Interface** : http://localhost:3000
- **Credentials** : admin / admin

### Loki
- **Role** : Stockage et indexation des logs (comme Prometheus mais pour les logs)
- **Fonctionnement** : Recoit les logs de Promtail, les indexe par labels
- **Port** : 3100 (interne)

### Promtail
- **Role** : Agent de collecte des logs
- **Fonctionnement** : Lit les logs des conteneurs Docker et les envoie a Loki
- **Port** : 9080 (interne)

## Les 3 piliers de l'observabilite

| Pilier | Outil | Description |
|--------|-------|-------------|
| **Metriques** | Prometheus | Donnees numeriques (latence, requetes, CPU...) |
| **Logs** | Loki + Promtail | Evenements textuels horodates |
| **Traces** | (non implemente) | Suivi des requetes a travers les services |

## Monitoring vs Observabilite

| Monitoring | Observabilite |
|------------|---------------|
| Surveille des metriques predefinies | Permet d'explorer l'inconnu |
| Alerte quand un seuil est depasse | Comprend pourquoi un probleme survient |
| Reactive | Proactive |
| "Le serveur est down" | "Pourquoi le serveur est down" |

## Integration avec l'application

### Backend NestJS
- Expose un endpoint `/metrics` au format Prometheus
- Metriques exposees :
  - `http_requests_total` : Nombre total de requetes
  - `http_request_duration_seconds` : Duree des requetes
  - `process_cpu_seconds_total` : Utilisation CPU
  - `process_resident_memory_bytes` : Memoire utilisee
  - `nodejs_eventloop_lag_seconds` : Lag de l'event loop

### Logs
- Les logs des conteneurs sont collectes via stdout
- Promtail les envoie a Loki avec des labels (container_name, service...)
- Visualisables dans Grafana via LogQL

## Ports d'execution

| Service | Port | URL |
|---------|------|-----|
| Grafana | 3000 | http://localhost:3000 |
| Prometheus | 9090 | http://localhost:9090 |
| Loki | 3100 | (interne) |
| Promtail | 9080 | (interne) |
| Backend metrics | 3000 | http://localhost:3000/metrics |

## Demarrage de la stack

```bash
# Lancer la stack monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Verifier les services
docker ps --filter "name=prometheus" --filter "name=grafana" --filter "name=loki" --filter "name=promtail"
```

## Dashboards disponibles

### Dashboard 1 : Metriques Backend
- Requetes HTTP par endpoint
- Latence moyenne (p50, p95, p99)
- Taux d'erreur
- Utilisation CPU/RAM

### Dashboard 2 : Logs & Correlation
- Logs par niveau (info, warn, error)
- Timeline des erreurs
- Correlation metriques/logs
