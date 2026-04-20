#!/usr/bin/env bash
#
# Build a simple index.html listing all published LoTE files.
# Usage: build-index.sh <output-dir>
#
set -euo pipefail

OUTPUT_DIR="${1:?Usage: build-index.sh <output-dir> [domain]}"
TRUST_DOMAIN="${2:-trust.siros.org}"

# Collect all published LoTE files
mapfile -t lote_files < <(find "$OUTPUT_DIR" -maxdepth 1 -name 'lote-*.json' -not -name '*.jws' | sort)

cat > "$OUTPUT_DIR/index.html" <<HEADER
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${TRUST_DOMAIN} — Trust Lists</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; max-width: 800px; margin: 2rem auto; padding: 0 1rem; color: #1a1a1a; }
    h1 { border-bottom: 2px solid #0066cc; padding-bottom: 0.5rem; }
    table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
    th, td { text-align: left; padding: 0.6rem 1rem; border-bottom: 1px solid #e0e0e0; }
    th { background: #f5f5f5; font-weight: 600; }
    a { color: #0066cc; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .meta { color: #666; font-size: 0.9rem; margin-top: 2rem; }
    code { background: #f0f0f0; padding: 0.15rem 0.4rem; border-radius: 3px; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>${TRUST_DOMAIN}</h1>
  <p>Published <a href="https://www.etsi.org/deliver/etsi_ts/119600_119699/119602/">ETSI TS 119 602</a>
     Lists of Trusted Entities (LoTE).</p>
  <table>
    <thead><tr><th>Trust List</th><th>Unsigned</th><th>Signed (JWS)</th></tr></thead>
    <tbody>
HEADER

for f in "${lote_files[@]}"; do
  name=$(basename "$f")
  jws_name="${name}.jws"
  label="${name%.json}"
  label="${label#lote-}"

  signed_col="-"
  if [ -f "$OUTPUT_DIR/$jws_name" ]; then
    signed_col="<a href=\"$jws_name\"><code>$jws_name</code></a>"
  fi

  cat >> "$OUTPUT_DIR/index.html" <<ROW
      <tr>
        <td><strong>${label}</strong></td>
        <td><a href="$name"><code>$name</code></a></td>
        <td>${signed_col}</td>
      </tr>
ROW
done

cat >> "$OUTPUT_DIR/index.html" <<FOOTER
    </tbody>
  </table>
  <p class="meta">
    Built $(date -u +"%Y-%m-%d %H:%M UTC") &middot;
    Source: <a href="https://github.com/sirosfoundation/trust-lists">sirosfoundation/trust-lists</a> &middot;
    Powered by <a href="https://github.com/sirosfoundation/g119612">g119612/tsl-tool</a>
  </p>
</body>
</html>
FOOTER

echo "Generated index.html with ${#lote_files[@]} trust list(s)"
