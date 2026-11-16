export async function register(): Promise<void> {
  if (process.env.NEXT_RUNTIME !== "nodejs") {
    return;
  }
  const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT?.trim();
  if (!endpoint) {
    return;
  }

  const { NodeSDK } = await import("@opentelemetry/sdk-node");
  const { OTLPTraceExporter } = await import(
    "@opentelemetry/exporter-trace-otlp-grpc"
  );
  const { Resource } = await import("@opentelemetry/resources");

  const url = endpoint.includes("://") ? endpoint : `http://${endpoint}`;
  const sdk = new NodeSDK({
    resource: new Resource({
      "service.name": process.env.OTEL_SERVICE_NAME?.trim() || "storefront",
    }),
    traceExporter: new OTLPTraceExporter({ url }),
  });
  sdk.start();
}
