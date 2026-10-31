# Icehouse – Local Setup Guide

## Prerequisite

Docker and Docker Compose must be installed.

## 1. Create the project folder

```
mkdir icehouse
cd icehouse
```

## 2. Create the `.env` file

```
nano .env
```

Content (change passwords if needed):

```
NESSIE_DB_PASSWORD=password
MINIO_ROOT_PASSWORD=password
JUPYTER_TOKEN=password
```

## 3. Create `docker-compose.yml`

```
nano docker-compose.yml
```

Content:

```yaml
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
```

## 4. Create the Trino catalog file

```
mkdir trino-catalog
nano trino-catalog/iceberg.properties
```

Content:

```properties
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
```

## 5. Start the containers

```
docker compose up -d
```

On first start, Docker will pull all images, which may take a while.

## 6. Create the MinIO bucket 

The warehouse path `s3a://icehouse/` requires a bucket named `icehouse` to exist in MinIO. It is **not** created automatically.

1. Open a browser: `http://localhost:9001`
2. Log in: username `admin`, password = the value of `MINIO_ROOT_PASSWORD` from `.env`
3. Create a new bucket named `icehouse`

## Expected folder structure

```
icehouse/
├── .env
├── docker-compose.yml
└── trino-catalog/
    └── iceberg.properties
```

## Access after startup

| Service       | URL                    | Login                         |
|---------------|------------------------|-------------------------------|
| Trino         | http://localhost:8080  | –                             |
| MinIO Console | http://localhost:9001  | admin / `MINIO_ROOT_PASSWORD` |
| Nessie API    | http://localhost:19120 | –                             |
| CloudBeaver   | http://localhost:8978  | –                             |
| JupyterLab    | http://localhost:8888  | Token = `JUPYTER_TOKEN`       |
