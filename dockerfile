FROM eclipse-temurin:21-jre-jammy

# Metadata
LABEL maintainer="Developer"
LABEL description="Apache Hive 4.0.1 Metastore"
LABEL version="4.0.1"
LABEL java.version="21"

# Environment variables for Hive
ENV HIVE_VERSION=4.0.1 \
    HADOOP_VERSION=3.4.0 \
    HADOOP_BINARY_VERSION=3.4.0-aarch64 \
    AWS_SDK_VERSION=2.35.8 \
    DELTA_VERSION=3.3.2 \
    DELTA_CORE_VERSION=2.4.0 \
    POSTGRESQL_JDBC_VERSION=42.7.8 \
    HIVE_HOME=/opt/hive \
    HADOOP_HOME=/opt/hadoop \
    # HADOOP_PREFIX=/opt/hadoop \
    PATH=$PATH:/opt/hadoop/bin

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    netcat-openbsd \
    curl \
    wget \
    procps \
    software-properties-common \
    gettext-base \
    tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/man/man1 && \ 
    wget -O- https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | tee /usr/share/keyrings/adoptium.gpg > /dev/null && \ 
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" | tee /etc/apt/sources.list.d/adoptium.list && \ 
    apt-get update && \ 
    apt-get install -y temurin-21-jdk && \ 
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r hive --gid=1000 && \
    useradd -r -g hive --uid=1000 --home-dir=${HIVE_HOME} --shell=/bin/bash hive && \
    mkdir -p ${HIVE_HOME}

RUN curl -fsSL https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_BINARY_VERSION}.tar.gz \
    | tar -xzC /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop

RUN curl -fsSL https://archive.apache.org/dist/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz | \
    tar -xzC ${HIVE_HOME} --strip-components=1 && \
    chown -R hive:hive ${HIVE_HOME}

RUN cd ${HIVE_HOME}/lib && \
    # Delta Lake
    wget -q https://repo1.maven.org/maven2/io/delta/delta-core_2.13/${DELTA_CORE_VERSION}/delta-core_2.13-${DELTA_CORE_VERSION}.jar && \
    wget -q https://repo1.maven.org/maven2/io/delta/delta-hive_2.13/${DELTA_VERSION}/delta-hive_2.13-${DELTA_VERSION}.jar && \
    wget -q https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar && \
    # AWS SDK for S3
    wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar && \
    wget -q https://repo1.maven.org/maven2/software/amazon/awssdk/bundle/${AWS_SDK_VERSION}/bundle-${AWS_SDK_VERSION}.jar && \
    # PostgreSQL JDBC Driver
    wget -q https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_JDBC_VERSION}.jar && \
    chown -R hive:hive *.jar

RUN mkdir -p ${HIVE_HOME}/conf && \
    mkdir -p ${HIVE_HOME}/logs && \
    chown -R hive:hive ${HIVE_HOME}/conf ${HIVE_HOME}/logs

COPY --chown=hive:hive conf/hive-site.xml ${HIVE_HOME}/conf/hive-site.xml

ENV HIVE_CONF_DIR=${HIVE_HOME}/conf \
    PATH=${HIVE_HOME}/bin:$PATH \
    JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-arm64

EXPOSE 9083 10000

COPY --chown=hive:hive scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

USER hive

WORKDIR ${HIVE_HOME}

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["metastore"]
