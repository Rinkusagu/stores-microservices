import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: [
    "@opentelemetry/sdk-node",
    "@opentelemetry/exporter-trace-otlp-grpc",
    "@opentelemetry/resources",
  ],
};

export default nextConfig;
