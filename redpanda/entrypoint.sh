#! /usr/bin/env /bin/bash
set -x
echo "Starting local redpanda..."
/usr/bin/rpk redpanda start \
--smp 1 \
--overprovisioned \
--kafka-addr internal://0.0.0.0:9092 \
--advertise-kafka-addr internal://redpanda:9092 \
--pandaproxy-addr internal://0.0.0.0:8082 \
--advertise-pandaproxy-addr internal://redpanda:8082 \
--schema-registry-addr internal://0.0.0.0:8081 \
--rpc-addr redpanda:33145 \
--advertise-rpc-addr redpanda:33145 \
--mode dev-container &

echo "Finalizing topic configuration..."
/usr/bin/rpk topic delete tpch packages transitions
/usr/bin/rpk topic create \
  -r 1 \
  -p 16 \
  -c cleanup.policy=delete \
  -c  log_retention_ms=3600000 \
  tpch packages transitions

echo "Stopping local redpanda..."
/usr/bin/rpk redpanda stop

echo "Starting public redpanda..."
/usr/bin/rpk redpanda start \
--smp 1 \
--overprovisioned \
--kafka-addr internal://0.0.0.0:9092,external://0.0.0.0:19092 \
--advertise-kafka-addr internal://redpanda:9092,external://$AWS_PUBLIC_HOSTNAME:19092 \
--pandaproxy-addr internal://0.0.0.0:8082,external://0.0.0.0:18082 \
--advertise-pandaproxy-addr internal://redpanda:8082,external://localhost:18082 \
--schema-registry-addr internal://0.0.0.0:8081,external://0.0.0.0:18081 \
--rpc-addr redpanda:33145 \
--advertise-rpc-addr redpanda:33145 \
--mode dev-container