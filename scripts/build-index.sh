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
    body { font-family: 'Helvetica Neue', Arial, system-ui, sans-serif; margin: 0; padding: 0; color: #1a1a1a; background: #fff; }

    /* ── Navbar ── */
    .navbar {
      background: #fff; border-bottom: 1px solid #e0e0e0;
      position: sticky; top: 0; z-index: 100;
    }
    .navbar-inner {
      max-width: 900px; margin: 0 auto;
      padding: 0.6rem 1.5rem; display: flex; align-items: center;
    }
    .navbar-brand { display: flex; align-items: center; gap: 0.6rem; text-decoration: none; color: #1C4587; font-weight: 600; font-size: 1.1rem; }
    .navbar-links { margin-left: auto; display: flex; gap: 1.25rem; align-items: center; }
    .navbar-links a { color: #555; text-decoration: none; font-size: 0.875rem; font-weight: 500; transition: color 0.2s; }
    .navbar-links a:hover { color: #1C4587; }
    .navbar-links a.active { color: #1C4587; border-bottom: 2px solid #1C4587; padding-bottom: 2px; }
    .navbar-links svg { width: 20px; height: 20px; fill: #555; transition: fill 0.2s; }
    .navbar-links a:hover svg { fill: #1C4587; }

    /* ── Main content ── */
    .content { max-width: 900px; margin: 2rem auto; padding: 0 1.5rem; }
    h1 { color: #1C4587; font-size: 1.6rem; margin-bottom: 0.5rem; font-weight: 700; }
    h2 { color: #1C4587; font-size: 1.25rem; font-weight: 600; }
    .subtitle { color: #555; margin-bottom: 1.5rem; font-size: 0.95rem; }
    table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
    th, td { text-align: left; padding: 0.6rem 1rem; border-bottom: 1px solid #e0e0e0; }
    th { background: #f8f9fa; font-weight: 600; font-size: 0.85rem; color: #555; text-transform: uppercase; letter-spacing: 0.03em; }
    a { color: #1C4587; text-decoration: none; }
    a:hover { text-decoration: underline; }
    code { background: #f0f0f0; padding: 0.15rem 0.4rem; border-radius: 3px; font-size: 0.9em; }

    /* ── Footer ── */
    .footer {
      border-top: 1px solid #e0e0e0; margin-top: 3rem;
      padding: 2rem 1.5rem; display: flex; align-items: center; justify-content: space-between;
      max-width: 900px; margin-left: auto; margin-right: auto;
      font-size: 0.875rem; color: #555;
    }
    .footer-logo { height: 40px; width: auto; }
    .footer-links { display: flex; align-items: center; gap: 1.25rem; flex-wrap: wrap; justify-content: flex-end; }
    .footer-links a { color: #555; text-decoration: none; transition: color 0.2s; }
    .footer-links a:hover { color: #1C4587; }
    .footer-links svg { width: 20px; height: 20px; fill: #555; transition: fill 0.2s; }
    .footer-links a:hover svg { fill: #1C4587; }
    @media (max-width: 640px) {
      .footer { flex-direction: column; gap: 1rem; text-align: center; }
      .footer-links { justify-content: center; }
    }
  </style>
</head>
<body>
  <nav class="navbar">
    <div class="navbar-inner">
    <a href="/" class="navbar-brand">
      <img src="static/siros-logo.png" alt="SIROS Foundation" style="height: 40px; width: auto;">
      <span style="margin-left: 0.5rem;">Trust Lists</span>
    </a>
    <div class="navbar-links">
      <a href="https://github.com/sirosfoundation/trust-lists" aria-label="GitHub">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 .5C5.73.5.66 5.57.66 11.84c0 5.02 3.25 9.27 7.76 10.77.57.1.78-.25.78-.55 0-.27-.01-1-.02-1.96-3.16.69-3.83-1.52-3.83-1.52-.52-1.32-1.27-1.67-1.27-1.67-1.04-.71.08-.69.08-.69 1.15.08 1.76 1.18 1.76 1.18 1.02 1.76 2.69 1.25 3.34.96.1-.74.4-1.25.72-1.54-2.52-.29-5.18-1.26-5.18-5.6 0-1.24.44-2.25 1.17-3.04-.12-.29-.51-1.45.11-3.02 0 0 .96-.31 3.15 1.16.91-.25 1.89-.38 2.86-.38.97 0 1.95.13 2.86.38 2.18-1.47 3.14-1.16 3.14-1.16.62 1.57.23 2.73.11 3.02.73.79 1.17 1.8 1.17 3.04 0 4.35-2.67 5.31-5.21 5.59.41.35.78 1.05.78 2.12 0 1.53-.01 2.76-.01 3.14 0 .31.21.66.79.55 4.5-1.5 7.75-5.75 7.75-10.77C23.34 5.57 18.27.5 12 .5Z"/></svg>
      </a>
    </div>
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
    <a href="/"><img src="static/siros-logo.png" alt="SIROS Foundation" class="footer-logo"></a>
    <div class="footer-links">
      <a href="https://github.com/sirosfoundation/trust-lists">Source</a>
      <a href="https://github.com/sirosfoundation/g119612">g119612/tsl-tool</a>
      <a href="https://github.com/sirosfoundation" aria-label="SIROS Foundation on GitHub">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 .5C5.73.5.66 5.57.66 11.84c0 5.02 3.25 9.27 7.76 10.77.57.1.78-.25.78-.55 0-.27-.01-1-.02-1.96-3.16.69-3.83-1.52-3.83-1.52-.52-1.32-1.27-1.67-1.27-1.67-1.04-.71.08-.69.08-.69 1.15.08 1.76 1.18 1.76 1.18 1.02 1.76 2.69 1.25 3.34.96.1-.74.4-1.25.72-1.54-2.52-.29-5.18-1.26-5.18-5.6 0-1.24.44-2.25 1.17-3.04-.12-.29-.51-1.45.11-3.02 0 0 .96-.31 3.15 1.16.91-.25 1.89-.38 2.86-.38.97 0 1.95.13 2.86.38 2.18-1.47 3.14-1.16 3.14-1.16.62 1.57.23 2.73.11 3.02.73.79 1.17 1.8 1.17 3.04 0 4.35-2.67 5.31-5.21 5.59.41.35.78 1.05.78 2.12 0 1.53-.01 2.76-.01 3.14 0 .31.21.66.79.55 4.5-1.5 7.75-5.75 7.75-10.77C23.34 5.57 18.27.5 12 .5Z"/></svg>
      </a>
      <span>&copy; $(date +%Y) SIROS Foundation</span>
    </div>
  </footer>
</body>
</html>
FOOTER

echo "Generated index.html with ${#lote_files[@]} LoTE(s), ${#lotl_files[@]} LoTL(s), and ${#tsl_files[@]} TSL(s)"
