#! /usr/bin/env /bin/bash
set -x
echo "Starting public redpanda..."
total_mem_k=$(grep MemTotal /proc/meminfo | awk '{print $2}')
eighty_percent_mem_gb=$(echo "scale=2; $total_mem_k / 1024 / 1024 * 0.80" | bc)
MEM_80_PERCENT_GB=$eighty_percent_mem_gb

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
--memory ${MEM_80_PERCENT_GB}G
#echo "Finalizing topic configuration..."
#/usr/bin/rpk topic delete tpch packages transitions
#/usr/bin/rpk topic create -r 1 -p 16 -c cleanup.policy=delete -c  log_retention_ms=3600000 tpch packages transitions

#echo "Stopping local redpanda..."
/usr/bin/rpk redpanda stop