export function burnCpu(ms: number): { burned_ms: number; iterations: number } {
  const duration = Math.max(1, Math.min(ms, 2000)) / 1000;
  const deadline = performance.now() + duration * 1000;
  let iterations = 0;
  while (performance.now() < deadline) {
    iterations += 1;
  }
  return { burned_ms: duration * 1000, iterations };
}
