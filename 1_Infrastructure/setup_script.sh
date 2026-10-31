 #!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Icehouse setup script
# Creates all required config files (if they don't exist yet), starts the
# docker compose stack and creates the required MinIO bucket automatically.
# ---------------------------------------------------------------------------

PROJECT_DIR="icehouse"

echo "==> Creating project folder: ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"
cd "${PROJECT_DIR}"

# ---------------------------------------------------------------------------
# .env file
# ---------------------------------------------------------------------------
if [ -f .env ]; then
  echo "==> .env already exists, skipping"
else
  echo "==> Creating .env"
  cat > .env <<'EOF'
NESSIE_DB_PASSWORD=password
MINIO_ROOT_PASSWORD=password
JUPYTER_TOKEN=password
EOF
fi

# Load env vars so this script can use them later (e.g. for the MinIO bucket step)
set -a
source .env
set +a

# ---------------------------------------------------------------------------
# docker-compose.yml
# ---------------------------------------------------------------------------
if [ -f docker-compose.yml ]; then
  echo "==> docker-compose.yml already exists, skipping"
else
  echo "==> Creating docker-compose.yml"
  cat > docker-compose.yml <<'EOF'
services:
  # 1. Nessie Catalog
  nessie:
    image: projectnessie/nessie:0.76.6
    container_name: nessie
    restart: always
    environment:
      - QUARKUS_PROFILE=prod
      - QUARKUS_HTTP_PORT=19120
      - NESSIE_CATALOG_ENABLED=true
      - NESSIE_VERSION.STORE_TYPE=JDBC
      - QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://nessie-db:5432/nessie
      - QUARKUS_DATASOURCE_USERNAME=nessie
      - QUARKUS_DATASOURCE_PASSWORD=${NESSIE_DB_PASSWORD}
    ports:
      - "19120:19120"
    networks:
      - icehouse-network
    depends_on:
      - nessie-db

  # 1b. Postgres database for Nessie metadata
  nessie-db:
    image: postgres:16-alpine
    container_name: nessie-db
    restart: always
    environment:
      - POSTGRES_DB=nessie
      - POSTGRES_USER=nessie
      - POSTGRES_PASSWORD=${NESSIE_DB_PASSWORD}
    volumes:
      - ./nessie-data:/var/lib/postgresql/data
    networks:
      - icehouse-network

  # 2. MinIO object storage
  minio:
    image: minio/minio
    container_name: minio
    restart: always
    environment:
      - MINIO_ROOT_USER=admin
      - MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./minio-data:/data
    command: server /data --console-address ":9001"
    networks:
      - icehouse-network

  # 3. Trino SQL query engine
  trino:
    image: trinodb/trino:443
    container_name: trino
    hostname: trino
    restart: always
    ports:
      - "8080:8080"
    environment:
      - MINIO_ACCESS_KEY=admin
      - MINIO_SECRET_KEY=${MINIO_ROOT_PASSWORD}
    volumes:
      - ./trino-catalog:/etc/trino/catalog
    command:
      - /usr/lib/trino/bin/launcher
      - run
      - --etc-dir=/etc/trino
      - -Dnode.internal-address=trino
      - -Dnode.environment=production
    networks:
      - icehouse-network

  # 4. CloudBeaver (SQL web UI)
  cloudbeaver:
    image: dbeaver/cloudbeaver:latest
    container_name: cloudbeaver
    restart: always
    ports:
      - "8978:8978"
    environment:
      - CLOUDBEAVER_PUBLIC_URL=http://localhost:8978
    volumes:
      - ./cloudbeaver-data:/opt/cloudbeaver/workspace
    networks:
      - icehouse-network

  # 5. JupyterLab
  jupyter:
    image: jupyter/datascience-notebook:latest
    container_name: jupyter
    restart: always
    ports:
      - "8888:8888"
    environment:
      - JUPYTER_TOKEN=${JUPYTER_TOKEN}
    volumes:
      - ./jupyter-notebooks:/home/jovyan/work
    networks:
      - icehouse-network

networks:
  icehouse-network:
    driver: bridge
EOF
fi

# ---------------------------------------------------------------------------
# Trino catalog config
# ---------------------------------------------------------------------------
mkdir -p trino-catalog
if [ -f trino-catalog/iceberg.properties ]; then
  echo "==> trino-catalog/iceberg.properties already exists, skipping"
else
  echo "==> Creating trino-catalog/iceberg.properties"
  cat > trino-catalog/iceberg.properties <<'EOF'
connector.name=iceberg
iceberg.catalog.type=nessie
iceberg.nessie-catalog.uri=http://nessie:19120/api/v1
iceberg.nessie-catalog.ref=main
iceberg.nessie-catalog.default-warehouse-dir=s3a://icehouse/

# S3 configuration
fs.native-s3.enabled=true
s3.endpoint=http://minio:9000
s3.path-style-access=true
s3.aws-access-key=${ENV:MINIO_ACCESS_KEY}
s3.aws-secret-key=${ENV:MINIO_SECRET_KEY}
s3.region=eu-central-1
EOF
fi

# ---------------------------------------------------------------------------
# Start the stack
# ---------------------------------------------------------------------------
echo "==> Starting containers"
docker compose up -d

# ---------------------------------------------------------------------------
# Wait for MinIO to be ready, then create the "icehouse" bucket automatically
# using the official minio/mc client (no local install required, runs in a
# throwaway container on the same docker network).
# ---------------------------------------------------------------------------
echo "==> Waiting for MinIO to become ready..."
until curl -s http://localhost:9000/minio/health/live > /dev/null; do
  sleep 2
done

echo "==> Creating MinIO bucket 'icehouse' (if it doesn't exist yet)"
docker run --rm --network icehouse_icehouse-network minio/mc \
  sh -c "mc alias set local http://minio:9000 admin ${MINIO_ROOT_PASSWORD} && \
         mc mb --ignore-existing local/icehouse"

echo ""
echo "==> Done! Services are available at:"
echo "    Trino:          http://localhost:8080"
echo "    MinIO Console:  http://localhost:9001  (admin / ${MINIO_ROOT_PASSWORD})"
echo "    Nessie API:     http://localhost:19120"
echo "    CloudBeaver:    http://localhost:8978"
echo "    JupyterLab:     http://localhost:8888  (token: ${JUPYTER_TOKEN})"
