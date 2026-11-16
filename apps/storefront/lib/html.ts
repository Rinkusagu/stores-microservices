export function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function page(body: string): string {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Resilient Commerce</title>
  <style>
    body { font-family: Georgia, serif; margin: 2rem auto; max-width: 42rem; color: #1c1917; }
    h1 { font-weight: 500; }
    table { border-collapse: collapse; width: 100%; }
    td, th { text-align: left; padding: 0.4rem 0.2rem; border-bottom: 1px solid #e7e5e4; }
    button { font: inherit; padding: 0.2rem 0.6rem; }
    .note { color: #44403c; }
  </style>
</head>
<body>
  <h1>Resilient Commerce</h1>
  ${body}
</body>
</html>`;
}
