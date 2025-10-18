# Apache Hive Metastore with Delta Lake and S3 Support

Lightweight Docker image for Apache Hive 4.0.1 Metastore (JDK 21) with built-in Delta Lake and AWS S3 integration.

## Features

- Apache Hive 4.0.1 Metastore
- Hadoop 3.4.0
- Delta Lake 3.3.2 (delta-hive connector)
- AWS SDK 2.35.8 for S3
- PostgreSQL JDBC driver
- Thrift metastore service

## Quick Start

1. Build the image:

   ```bash
   docker build -t hive_local .
   ```

2. Use it in your `docker-compose.yml`:

   ```yaml
   hive-metastore:
     image: hive_local
     ports:
       - "9083:9083"
   ```

## Exposed Ports

- 9083 – Hive Metastore Thrift service
- 10000 – HiveServer2 (if enabled)

## Configuration

Mount `hive-site.xml` to `/opt/hive/conf/hive-site.xml` to customize:
- Database connection (PostgreSQL)
- S3 credentials and endpoint
- Warehouse location
