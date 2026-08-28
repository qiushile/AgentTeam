#!/bin/bash
# deploy-otel.sh — OpenTelemetry 部署脚本
# 用法: ./deploy-otel.sh [start|stop|status|logs]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/docker-compose"

ACTION="${1:-status}"

case "$ACTION" in
  start)
    echo "🚀 Starting OpenTelemetry Collector..."
    docker-compose -f "$COMPOSE_DIR/otel-collector.yml" up -d
    echo "🚀 Starting Grafana Tempo..."
    docker-compose -f "$COMPOSE_DIR/tempo.yml" up -d
    echo "⏳ Waiting for services to be ready..."
    sleep 5
    echo "✅ Checking health..."
    curl -sf http://localhost:4318/ || echo "Collector HTTP: not ready yet"
    curl -sf http://localhost:3200/status && echo "Tempo: ready" || echo "Tempo: not ready yet"
    curl -sf http://localhost:8888/metrics | head -5 && echo "Collector metrics: ready" || echo "Collector metrics: not ready yet"
    ;;
  stop)
    echo "🛑 Stopping OpenTelemetry services..."
    docker-compose -f "$COMPOSE_DIR/otel-collector.yml" down
    docker-compose -f "$COMPOSE_DIR/tempo.yml" down
    echo "✅ Stopped"
    ;;
  status)
    echo "📊 OpenTelemetry Service Status"
    echo "=============================="
    echo ""
    docker-compose -f "$COMPOSE_DIR/otel-collector.yml" ps 2>/dev/null || echo "Collector: not deployed"
    echo ""
    docker-compose -f "$COMPOSE_DIR/tempo.yml" ps 2>/dev/null || echo "Tempo: not deployed"
    echo ""
    echo "Endpoints:"
    echo "  OTLP gRPC:  localhost:4317"
    echo "  OTLP HTTP:  localhost:4318"
    echo "  Tempo API:  localhost:3200"
    echo "  Metrics:    localhost:8888"
    ;;
  logs)
    echo "📋 OpenTelemetry Logs"
    echo "===================="
    echo ""
    echo "--- Collector Logs ---"
    docker-compose -f "$COMPOSE_DIR/otel-collector.yml" logs --tail=50
    echo ""
    echo "--- Tempo Logs ---"
    docker-compose -f "$COMPOSE_DIR/tempo.yml" logs --tail=50
    ;;
  *)
    echo "Usage: $0 {start|stop|status|logs}"
    exit 1
    ;;
esac
