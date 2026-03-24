# Plan de deploiement Blue/Green

## Architecture

```
                    ┌─────────────────┐
                    │     Client      │
                    └────────┬────────┘
                             │ :80
                    ┌────────▼────────┐
                    │  Reverse Proxy  │
                    │     (Nginx)     │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐           ┌────────▼────────┐
     │      BLUE       │           │      GREEN      │
     │  (version N)    │           │  (version N+1)  │
     ├─────────────────┤           ├─────────────────┤
     │ frontend-blue   │           │ frontend-green  │
     │ backend-blue    │           │ backend-green   │
     └────────┬────────┘           └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                    ┌────────▼────────┐
                    │    PostgreSQL   │
                    │   (partage)     │
                    └─────────────────┘
```

## Strategie de fichiers Docker Compose

### Structure des fichiers

| Fichier | Contenu |
|---------|---------|
| `docker-compose.base.yml` | PostgreSQL + Reverse Proxy (infra partagee) |
| `docker-compose.blue.yml` | frontend-blue + backend-blue |
| `docker-compose.green.yml` | frontend-green + backend-green |

### Reseau

Tous les services partagent le meme reseau `app-network` pour permettre la communication.

## Mecanisme de bascule

### Option choisie : Fichier de configuration Nginx dynamique

Le reverse proxy utilise un fichier `active-color.conf` qui definit la couleur active :

```nginx
# active-color.conf
set $active_color blue;  # ou green
```

Ce fichier est monte dans le conteneur Nginx et inclus dans la configuration principale.

### Pourquoi ce choix ?

1. **Simple** : Un seul fichier a modifier
2. **Rapide** : `nginx -s reload` suffit (pas de restart)
3. **Rollback instantane** : Changer "blue" en "green" et reload

## Scenario de deploiement

### Etat initial
- Couleur active : `blue`
- Version en production : N
- `green` peut etre arrete ou contenir une ancienne version

### Deploiement d'une nouvelle version

1. **Lire la couleur active actuelle**
   ```bash
   ACTIVE=$(cat nginx/active-color.conf | grep -oP '(?<=set \$active_color )\w+')
   # ACTIVE = "blue"
   ```

2. **Determiner la couleur cible**
   ```bash
   if [ "$ACTIVE" = "blue" ]; then
     TARGET="green"
   else
     TARGET="blue"
   fi
   # TARGET = "green"
   ```

3. **Deployer sur la couleur inactive**
   ```bash
   docker compose -f docker-compose.base.yml -f docker-compose.${TARGET}.yml up -d
   ```

4. **Attendre que les services soient prets**
   ```bash
   # Health check sur backend-green:3000
   ```

5. **Basculer le proxy**
   ```bash
   echo 'set $active_color green;' > nginx/active-color.conf
   docker exec reverse-proxy nginx -s reload
   ```

6. **Nouvelle version en production**

### Rollback

En cas de probleme :

```bash
# Revenir a blue
echo 'set $active_color blue;' > nginx/active-color.conf
docker exec reverse-proxy nginx -s reload
```

Temps de rollback : < 1 seconde

## Commandes de reference

### Lancer l'infrastructure de base
```bash
docker compose -f docker-compose.base.yml up -d
```

### Deployer blue
```bash
docker compose -f docker-compose.base.yml -f docker-compose.blue.yml up -d
```

### Deployer green
```bash
docker compose -f docker-compose.base.yml -f docker-compose.green.yml up -d
```

### Basculer vers blue
```bash
echo 'set $active_color blue;' > nginx/active-color.conf
docker exec reverse-proxy nginx -s reload
```

### Basculer vers green
```bash
echo 'set $active_color green;' > nginx/active-color.conf
docker exec reverse-proxy nginx -s reload
```

### Verifier la couleur active
```bash
cat nginx/active-color.conf
```

## Points de vigilance

1. **Base de donnees unique** : Les migrations doivent etre retrocompatibles
2. **Health checks** : Toujours verifier que la nouvelle version repond avant de basculer
3. **Pas de --volumes** : Ne jamais utiliser `docker compose down --volumes`
4. **Logs** : Surveiller les logs du proxy et des applications pendant la bascule
