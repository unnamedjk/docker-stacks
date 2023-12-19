version: '3.7'
name: redpanda
networks:
  redpanda_network:
    driver: bridge
volumes:
  redpanda: null
services:
  redpanda:
    restart: always
    image: docker.redpanda.com/redpandadata/redpanda:v23.2.19
    env_file: .env
    command:
      - redpanda start
      - --smp 1
      - --overprovisioned
      - --kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092
      - --advertise-kafka-addr internal://redpanda:9092,external://$AWS_PUBLIC_HOSTNAME:19092
      - --pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082
      - --advertise-pandaproxy-addr internal://redpanda:8082,external://localhost:18082
      - --schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081
      - --rpc-addr redpanda:33145
      - --advertise-rpc-addr redpanda:33145
      - --mode dev-container
    ports:
      - 18081:18081
      - 18082:18082
      - 19092:19092
      - 19644:9644
    volumes:
      - redpanda:/var/lib/redpanda/data
    networks:
      - redpanda_network
    healthcheck:
      test: ["CMD-SHELL", "rpk cluster health | grep -E 'Healthy:.+true' || exit 1"]
      interval: 15s
      timeout: 3s
      retries: 5
      start_period: 5s
  console:
    image: docker.redpanda.com/redpandadata/console:v2.3.8
    restart: always
    entrypoint: /bin/sh
    command: -c 'echo "$$CONSOLE_CONFIG_FILE" > /tmp/config.yml && echo "$$CONSOLE_ROLEBINDINGS_CONFIG_FILE" > /tmp/role-bindings.yml && /app/console'
    environment:
      CONFIG_FILEPATH: /tmp/config.yml
      CONSOLE_CONFIG_FILE: |
        kafka:
          brokers: ["redpanda:9092"]
          schemaRegistry:
            enabled: true
            urls: ["http://redpanda:8081"]
        redpanda:
          adminApi:
            enabled: true
            urls: ["http://redpanda:9644"]
        connect:
          enabled: true
          clusters:
            - name: local-connect-cluster
              url: http://connect:8083
    ports:
      - 8080:8080
    networks:
      - redpanda_network
    depends_on:
      - redpanda
  connect:
    image: docker.redpanda.com/redpandadata/connectors:latest
    restart: always
    hostname: connect
    container_name: connect
    networks:
      - redpanda_network
    depends_on:
      - redpanda
    ports:
      - "8083:8083"
    environment:
      CONNECT_CONFIGURATION: |
          key.converter=org.apache.kafka.connect.converters.ByteArrayConverter
          value.converter=org.apache.kafka.connect.converters.ByteArrayConverter
          group.id=connectors-cluster
          offset.storage.topic=_internal_connectors_offsets
          config.storage.topic=_internal_connectors_configs
          status.storage.topic=_internal_connectors_status
          config.storage.replication.factor=-1
          offset.storage.replication.factor=-1
          status.storage.replication.factor=-1
          offset.flush.interval.ms=1000
          producer.linger.ms=50
          producer.batch.size=131072
      CONNECT_BOOTSTRAP_SERVERS: redpanda:9092
      CONNECT_GC_LOG_ENABLED: "false"
      CONNECT_HEAP_OPTS: -Xms512M -Xmx512M
      CONNECT_LOG_LEVEL: info