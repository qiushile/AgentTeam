// tracing.js — OpenTelemetry 自动插桩入口
// 使用方式: node -r ./tracing.js app.js
// 环境变量:
//   OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318 (默认)
//   OTEL_SERVICE_NAME=dev-workspace (默认)
//   OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const {
  SEMRESATTRS_SERVICE_NAME,
  SEMRESATTRS_SERVICE_VERSION,
  SEMRESATTRS_DEPLOYMENT_ENVIRONMENT,
} = require('@opentelemetry/semantic-conventions');

// 配置
const OTEL_ENDPOINT = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';
const SERVICE_NAME = process.env.OTEL_SERVICE_NAME || 'dev-workspace';
const SERVICE_VERSION = process.env.OTEL_SERVICE_VERSION || '1.0.0';
const ENVIRONMENT = process.env.DEPLOYMENT_ENVIRONMENT || 'production';

console.log(`[OTEL] Initializing OpenTelemetry SDK for ${SERVICE_NAME} v${SERVICE_VERSION}`);
console.log(`[OTEL] Collector endpoint: ${OTEL_ENDPOINT}`);
console.log(`[OTEL] Environment: ${ENVIRONMENT}`);

const traceExporter = new OTLPTraceExporter({
  url: `${OTEL_ENDPOINT}/v1/traces`,
});

const metricExporter = new OTLPMetricExporter({
  url: `${OTEL_ENDPOINT}/v1/metrics`,
});

const sdk = new NodeSDK({
  resource: new Resource({
    [SEMRESATTRS_SERVICE_NAME]: SERVICE_NAME,
    [SEMRESATTRS_SERVICE_VERSION]: SERVICE_VERSION,
    [SEMRESATTRS_DEPLOYMENT_ENVIRONMENT]: ENVIRONMENT,
    'service.namespace': 'dev',
    'telemetry.sdk.language': 'nodejs',
  }),
  traceExporter,
  metricExporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      // HTTP 插桩
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingPaths: ['/health', '/healthz', '/ready'],
        requireParentforOutgoingSpans: false,
      },
      // Express 插桩
      '@opentelemetry/instrumentation-express': {
        enabled: true,
        requestHook: (span, info) => {
          if (info.request?.route?.path) {
            span.setAttribute('http.route', info.request.route.path);
          }
        },
      },
      // PostgreSQL 插桩
      '@opentelemetry/instrumentation-pg': {
        enhancedDatabaseReporting: true,
        requireParentSpan: false,
      },
      // FS 插桩
      '@opentelemetry/instrumentation-fs': {
        enabled: true,
      },
    }),
  ],
});

sdk.start();

console.log('[OTEL] SDK started successfully');

// 优雅关闭
process.on('SIGTERM', async () => {
  console.log('[OTEL] Shutting down SDK...');
  await sdk.shutdown();
  console.log('[OTEL] SDK shut down complete');
});

module.exports = { sdk };
