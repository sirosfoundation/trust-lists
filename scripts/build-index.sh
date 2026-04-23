#!/usr/bin/env bash
#
# Build a simple index.html listing all published trust list files.
# Usage: build-index.sh <output-dir>
#
set -euo pipefail

OUTPUT_DIR="${1:?Usage: build-index.sh <output-dir> [domain]}"
TRUST_DOMAIN="${2:-trust.siros.org}"

# Collect all published LoTE JSON files (any .json that isn't a LoTL or JWS)
mapfile -t lote_files < <(find "$OUTPUT_DIR" -maxdepth 1 -name '*.json' \
  -not -name '*.jws' \
  -not -name 'list_of_trusted_lists*' \
  | sort)

# Collect all published LoTL JSON files
mapfile -t lotl_files < <(find "$OUTPUT_DIR" -maxdepth 1 -name 'list_of_trusted_lists*.json' \
  -not -name '*.jws' \
  | sort)

# Collect all published TSL XML files (exclude LoTE XML since those are listed with their JSON)
mapfile -t tsl_files < <(find "$OUTPUT_DIR" -maxdepth 1 -name '*.xml' | sort)

cat > "$OUTPUT_DIR/index.html" <<HEADER
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${TRUST_DOMAIN} — Trust Lists</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; margin: 0; padding: 0; color: #1a1a1a; background: #fff; }

    /* ── Navbar ── */
    .navbar {
      background: #fff; border-bottom: 1px solid #e0e0e0;
      padding: 0.6rem 1.5rem; display: flex; align-items: center;
      position: sticky; top: 0; z-index: 100;
    }
    .navbar-brand { display: flex; align-items: center; gap: 0.6rem; text-decoration: none; color: #1C4587; font-weight: 600; font-size: 1.1rem; }
    .navbar-brand svg { width: 32px; height: 32px; }
    .navbar-links { margin-left: auto; display: flex; gap: 1.25rem; align-items: center; }
    .navbar-links a { color: #444; text-decoration: none; font-size: 0.9rem; font-weight: 500; }
    .navbar-links a:hover { color: #1C4587; }
    .navbar-links a.active { color: #1C4587; border-bottom: 2px solid #1C4587; padding-bottom: 2px; }

    /* ── Main content ── */
    .content { max-width: 900px; margin: 2rem auto; padding: 0 1.5rem; }
    h1 { color: #1C4587; font-size: 1.6rem; margin-bottom: 0.5rem; }
    .subtitle { color: #555; margin-bottom: 1.5rem; }
    table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
    th, td { text-align: left; padding: 0.6rem 1rem; border-bottom: 1px solid #e0e0e0; }
    th { background: #f8f9fa; font-weight: 600; font-size: 0.85rem; color: #555; text-transform: uppercase; letter-spacing: 0.03em; }
    a { color: #1C4587; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code { background: #f0f0f0; padding: 0.15rem 0.4rem; border-radius: 3px; font-size: 0.9em; }

    /* ── Footer ── */
    .footer {
      border-top: 1px solid #e0e0e0; margin-top: 3rem;
      padding: 1.5rem; text-align: center; color: #666; font-size: 0.85rem;
    }
    .footer a { color: #1C4587; }
  </style>
</head>
<body>
  <nav class="navbar">
    <a href="/" class="navbar-brand">
      <svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="512" height="512" rx="256" fill="white"/><path fill-rule="evenodd" clip-rule="evenodd" d="M190.286 109.335C201.858 184.5 201.858 184.5 277.023 196.127C201.884 207.695 201.858 207.865 190.298 282.896C190.294 282.922 190.29 282.948 190.286 282.974C178.658 207.754 178.658 207.754 103.494 196.127C178.658 184.5 178.658 184.5 190.286 109.335ZM196.127 326.068C327.831 305.678 327.831 305.678 348.22 173.919C368.059 302.317 368.554 305.623 490.394 324.525C496.732 302.758 500.148 279.778 500.148 256.028C500.148 121.128 390.872 11.8518 255.972 11.8518C121.128 11.8518 11.8518 121.128 11.8518 256.028C11.8518 390.872 121.128 500.148 255.972 500.148C365.909 500.148 458.818 427.573 489.458 327.721C368.499 346.457 368.003 350.314 348.22 478.106C327.831 346.402 327.831 346.402 196.127 326.068Z" fill="#1C4587"/></svg>
      Trust Lists
    </a>
    <div class="navbar-links">
      <a href="https://github.com/sirosfoundation/trust-lists">GitHub</a>
    </div>
  </nav>

  <div class="content">
  <h1>${TRUST_DOMAIN}</h1>
  <p class="subtitle">Published <a href="https://www.etsi.org/deliver/etsi_ts/119600_119699/119602/">ETSI TS 119 602</a>
     Lists of Trusted Entities (LoTE) and <a href="https://www.etsi.org/deliver/etsi_ts/119600_119699/119612/">ETSI TS 119 612</a>
     Trust Status Lists (TSL).</p>
  <h2>Lists of Trusted Entities (LoTE)</h2>
  <table>
    <thead><tr><th>Trust List</th><th>Unsigned</th><th>Signed (JWS)</th></tr></thead>
    <tbody>
HEADER

for f in "${lote_files[@]}"; do
  name=$(basename "$f")
  jws_name="${name}.jws"
  label="${name%.json}"

  signed_col="-"
  if [ -f "$OUTPUT_DIR/$jws_name" ]; then
    signed_col="<a href=\"$jws_name\"><code>$jws_name</code></a>"
  fi

  xml_name="${label}.xml"
  xml_col=""
  if [ -f "$OUTPUT_DIR/$xml_name" ]; then
    xml_col=" &middot; <a href=\"$xml_name\"><code>XML</code></a>"
  fi

  cat >> "$OUTPUT_DIR/index.html" <<ROW
      <tr>
        <td><strong>${label}</strong></td>
        <td><a href="$name"><code>$name</code></a>${xml_col}</td>
        <td>${signed_col}</td>
      </tr>
ROW
done

cat >> "$OUTPUT_DIR/index.html" <<LOTE_END
    </tbody>
  </table>

LOTE_END

# ── LoTL section ──
if [ ${#lotl_files[@]} -gt 0 ]; then
  cat >> "$OUTPUT_DIR/index.html" <<LOTL_HEADER
  <h2>Lists of Trusted Lists (LoTL)</h2>
  <table>
    <thead><tr><th>List of Lists</th><th>JSON</th><th>Signed (JWS)</th></tr></thead>
    <tbody>
LOTL_HEADER

  for f in "${lotl_files[@]}"; do
    name=$(basename "$f")
    jws_name="${name}.jws"
    label="${name%.json}"

    signed_col="-"
    if [ -f "$OUTPUT_DIR/$jws_name" ]; then
      signed_col="<a href=\"$jws_name\"><code>$jws_name</code></a>"
    fi

    xml_name="${label}.xml"
    xml_col=""
    if [ -f "$OUTPUT_DIR/$xml_name" ]; then
      xml_col=" &middot; <a href=\"$xml_name\"><code>XML</code></a>"
    fi

    cat >> "$OUTPUT_DIR/index.html" <<ROW
      <tr>
        <td><strong>${label}</strong></td>
        <td><a href="$name"><code>$name</code></a>${xml_col}</td>
        <td>${signed_col}</td>
      </tr>
ROW
  done

  cat >> "$OUTPUT_DIR/index.html" <<LOTL_END
    </tbody>
  </table>

LOTL_END
fi

# ── TSL section ──
if [ ${#tsl_files[@]} -gt 0 ]; then
  cat >> "$OUTPUT_DIR/index.html" <<TSL_HEADER
  <h2>Trust Status Lists (TSL)</h2>
  <table>
    <thead><tr><th>Trust List</th><th>XML</th></tr></thead>
    <tbody>
TSL_HEADER

  for f in "${tsl_files[@]}"; do
    name=$(basename "$f")
    label="${name%.xml}"

    cat >> "$OUTPUT_DIR/index.html" <<ROW
      <tr>
        <td><strong>${label}</strong></td>
        <td><a href="$name"><code>$name</code></a></td>
      </tr>
ROW
  done

  cat >> "$OUTPUT_DIR/index.html" <<TSL_END
    </tbody>
  </table>
TSL_END
fi

cat >> "$OUTPUT_DIR/index.html" <<FOOTER
  </div>

  <footer class="footer">
    Copyright &copy; $(date +%Y) SIROS Foundation &middot;
    Built $(date -u +"%Y-%m-%d %H:%M UTC") &middot;
    <a href="https://github.com/sirosfoundation/trust-lists">Source</a> &middot;
    <a href="https://github.com/sirosfoundation/g119612">g119612/tsl-tool</a>
  </footer>
</body>
</html>
FOOTER

echo "Generated index.html with ${#lote_files[@]} LoTE(s), ${#lotl_files[@]} LoTL(s), and ${#tsl_files[@]} TSL(s)"
