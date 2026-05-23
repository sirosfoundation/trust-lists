#!/usr/bin/env bash
#
# Generate status.json for external monitoring (e.g. instatus.com).
# Checks that signed artifacts exist and reports aggregate health.
#
# Usage: build-status.sh <output-dir>
#
set -euo pipefail

OUTPUT_DIR="${1:?Usage: build-status.sh <output-dir>}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
STATUS="ok"
LISTS_JSON="[]"

# Collect per-list signing status
entries=()
for jws in "$OUTPUT_DIR"/*.jws; do
  [ -f "$jws" ] || continue
  name=$(basename "$jws" .json.jws)
  size=$(stat --printf="%s" "$jws" 2>/dev/null || stat -f%z "$jws" 2>/dev/null || echo "0")
  if [ "$size" -gt 0 ]; then
    entries+=("{\"name\":\"$name\",\"signed\":true}")
  else
    entries+=("{\"name\":\"$name\",\"signed\":false}")
    STATUS="degraded"
  fi
done

# Check XML signatures (TSL files contain embedded XML-DSIG)
for xml in "$OUTPUT_DIR"/*.xml; do
  [ -f "$xml" ] || continue
  name=$(basename "$xml" .xml)
  # Skip if already counted via JWS (LoTE XML companions)
  if printf '%s\n' "${entries[@]}" | grep -q "\"$name\""; then
    continue
  fi
  if grep -q '<ds:Signature\|<Signature' "$xml" 2>/dev/null; then
    entries+=("{\"name\":\"$name\",\"signed\":true}")
  else
    entries+=("{\"name\":\"$name\",\"signed\":false}")
    STATUS="degraded"
  fi
done

# If no signed artifacts at all, mark as down
if [ ${#entries[@]} -eq 0 ]; then
  STATUS="down"
fi

# Build JSON array
LISTS_JSON=$(printf '%s,' "${entries[@]}" | sed 's/,$//')

cat > "$OUTPUT_DIR/status.json" <<EOF
{
  "status": "$STATUS",
  "lastBuild": "$TIMESTAMP",
  "signingMode": "${SIGNING_MODE:-unknown}",
  "lists": [$LISTS_JSON]
}
EOF

echo "Generated status.json: status=$STATUS, ${#entries[@]} list(s)"
