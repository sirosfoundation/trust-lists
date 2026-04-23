# trust-lists

Published [ETSI TS 119 602](https://www.etsi.org/deliver/etsi_ts/119600_119699/119602/)
Lists of Trusted Entities (LoTE) and Trust Status Lists (TSL) for the EUDI wallet ecosystem.

**Live site:** [trust.siros.org](https://trust.siros.org)

## How it works

1. Trust list source data lives under `lists/` as YAML + certificates
2. Each subdirectory contains a `.pipeline.yaml` that defines its processing pipeline
3. Pull requests add, update, or remove trusted entities — reviewed before merge
4. On merge to `main`, GitHub Actions runs
   [g119612/tsl-tool](https://github.com/sirosfoundation/g119612) to execute
   each directory's pipeline, generating and signing the output documents
5. Signed output is deployed to GitHub Pages at `trust.siros.org`

## Repository structure

```
lists/
  <instance>/                   # One directory per trust list
    .pipeline.yaml              # Pipeline steps (defines list type)
    scheme.yaml                 # Scheme metadata
    entities/                   # LoTE: trusted entities
      <entity>/
        entity.yaml
        cert.pem / key.jwk      # Public key (optional)
    providers/                  # TSL: trust service providers
      <provider>/
        provider.yaml
        <service>/
          cert.pem
          cert.yaml

pipelines/                      # Custom pipelines (e.g. EU LOTL fetch)
static/                         # Assets for the landing page
templates/                      # HTML templates
scripts/                        # Build helpers
```

The `.pipeline.yaml` determines what type of trust list each directory produces
(LoTE, TSL, LoTL, or a combination). Not every directory needs `entities/` or
`providers/` — only the subdirectories relevant to that pipeline.

## Adding a trusted entity

1. Create a branch and add a directory under `lists/<instance>/entities/<name>/`
2. Add `entity.yaml` with the entity metadata:
   ```yaml
   names:
     - language: en
       value: "My Organization"
   entityId: "https://example.com"
   status: "http://uri.etsi.org/TrstSvc/TrustedList/Svcstatus/granted"
   services:
     - serviceNames:
         - language: en
           value: "Credential Issuance Service"
       serviceType: "http://uri.etsi.org/TrstSvc/Svctype/CA/QC"
       status: "http://uri.etsi.org/TrstSvc/TrustedList/Svcstatus/granted"
   ```
3. Optionally add `cert.pem` (X.509) or `key.jwk` (JWK) for the entity's public key
4. Open a pull request — CI validates the structure automatically
5. After review and merge, the trust list is rebuilt and published

## Creating a new trust list instance

1. Create a directory under `lists/<name>/`
2. Add `scheme.yaml`:
   ```yaml
   operatorNames:
     - language: en
       value: "My Trust Scheme Operator"
   schemeName:
     - language: en
       value: "My Trust Scheme"
   schemeType: "http://uri.etsi.org/TrstSvc/TrustedList/TSLType/EUgeneric"
   territory: "demo"
   sequenceNumber: 1
   ```
3. Add entities under `entities/` as described above

## Creating a TSL instance (ETSI TS 119 612)

1. Create a directory under `lists/<name>/`
2. Add `scheme.yaml`:
   ```yaml
   operatorNames:
     - language: en
       value: "My Trust Scheme Operator"
   type: "http://uri.etsi.org/TrstSvc/TrustedList/TSLType/EUgeneric"
   sequenceNumber: 1
   ```
3. Add providers under `providers/<provider-name>/`:
   - `provider.yaml`:
     ```yaml
     names:
       - language: en
         value: "My Trust Service Provider"
     informationURI:
       - language: en
         value: "https://example.com"
     ```
   - For each trust service, create a subdirectory with `cert.pem` and `cert.yaml`:
     ```yaml
     serviceNames:
       - language: en
         value: "Credential Issuance Service"
     serviceType: "http://uri.etsi.org/TrstSvc/Svctype/CA/QC"
     status: "http://uri.etsi.org/TrstSvc/TrustedList/Svcstatus/granted"
     ```
4. Open a pull request — CI validates the structure automatically
5. After review and merge, the TSL is rebuilt and published as XML with XML-DSIG

## Signing

Trust lists are signed via a PKCS#11 interface — LoTEs use JWS (JSON Web Signature),
TSLs use XML-DSIG (XML Digital Signature with XAdES).

| Mode | `DEFAULT_SIGNING_MODE` | Runner | Key persistence | Use case |
|------|------------------------|--------|-----------------|----------|
| **dev** | `dev` | `ubuntu-latest` | Ephemeral (new key each build) | CI testing, quick validation |
| **softhsm** | `softhsm` | Self-hosted | Persistent SoftHSM2 token on runner | Staging, pre-production |
| **yubihsm** | `yubihsm` | Self-hosted | YubiHSM2 hardware | Production |

The signing mode is controlled by the `DEFAULT_SIGNING_MODE` repository variable
or the `signing_mode` workflow dispatch input.

### Setting up a self-hosted runner with persistent SoftHSM2

Run the setup script once on the runner host:

```bash
sudo apt-get install -y softhsm2 opensc
sudo ./scripts/setup-softhsm-runner.sh \
  --runner-user runner \
  --cert-subject "/CN=trust.siros.org Trust List Signer"
```

Then configure the repo (the script prints the exact values):

**Variables** (Settings → Variables → Actions):

| Variable | Example |
|----------|---------|
| `DEFAULT_SIGNING_MODE` | `softhsm` |
| `SOFTHSM_CONF_PATH` | `/etc/softhsm/trust-lists.conf` |
| `SOFTHSM_TOKEN_LABEL` | `trust-lists` |
| `SOFTHSM_KEY_LABEL` | `signing-key` |
| `SOFTHSM_CERT_LABEL` | `signing-cert` |
| `SOFTHSM_KEY_ID` | `01` |

**Secrets** (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `SOFTHSM_PIN` | User PIN for the SoftHSM2 token |

### GitHub Secrets (YubiHSM2 production)

| Secret | Description |
|--------|-------------|
| `YUBIHSM_PKCS11_MODULE` | Path to `yubihsm_pkcs11.so` on the runner |
| `YUBIHSM_PIN` | HSM authentication PIN |
| `YUBIHSM_TOKEN_LABEL` | Token label |
| `YUBIHSM_KEY_LABEL` | Signing key label |
| `YUBIHSM_CERT_LABEL` | Signing certificate label |
| `YUBIHSM_KEY_ID` | Key ID (hex, e.g. `01`) |

## Pipeline files

Each `lists/<instance>/` directory contains a `.pipeline.yaml` that
defines the processing steps for that trust list. The workflow reads each file,
expands `${ENV_VAR}` placeholders with `envsubst`, and passes the result to
`tsl-tool`.

Example — a LoTE list (`lists/siros-demo/.pipeline.yaml`):

```yaml
- generate-lote:
    - ${LIST_DIR}
- increment-lote-sequence: []
- publish-lote:
    - ${OUTPUT_DIR}
    - ${PKCS11_URI}
    - ${PKCS11_KEY_LABEL}
    - ${PKCS11_CERT_LABEL}
    - ${PKCS11_KEY_ID}
    - xml
```

Example — a TSL with LoTE conversion (`lists/ewc-demo/.pipeline.yaml`):

```yaml
- generate:
    - ${LIST_DIR}
- publish:
    - ${OUTPUT_DIR}
    - ${PKCS11_URI}
    - ${PKCS11_KEY_LABEL}
    - ${PKCS11_CERT_LABEL}
    - ${PKCS11_KEY_ID}
- convert-to-lote: []
- publish-lote:
    - ${OUTPUT_DIR}
    - ${PKCS11_URI}
    - ${PKCS11_KEY_LABEL}
    - ${PKCS11_CERT_LABEL}
    - ${PKCS11_KEY_ID}
    - xml
```

Example — a List of Trusted Lists (`lists/siros-demo-lotl/.pipeline.yaml`):

```yaml
- generate-lotl:
    - ${LIST_DIR}
- publish-lote:
    - ${OUTPUT_DIR}
    - ${PKCS11_URI}
    - ${PKCS11_KEY_LABEL}
    - ${PKCS11_CERT_LABEL}
    - ${PKCS11_KEY_ID}
```

The `xml` flag on `publish-lote` controls whether an XML companion is also
generated alongside the JSON output.

## Output

Each LoTE trust list produces:

- `lote-<name>.json` — Unsigned LoTE JSON
- `lote-<name>.json.jws` — JWS-signed LoTE
- `lote-<name>.xml` — LoTE XML (when `xml` flag is set in the pipeline)

Each TSL produces:

- `<name>.xml` — Signed TSL XML (XML-DSIG with XAdES)

TSLs with a `convert-to-lote` step additionally produce:

- `<name>.json` — Converted LoTE JSON
- `<name>.json.jws` — JWS-signed converted LoTE
- `<name>.xml` — LoTE XML (when `xml` flag is set)

Each LoTL produces:

- `list_of_trusted_lists-<name>.json` — LoTL JSON
- `list_of_trusted_lists-<name>.json.jws` — JWS-signed LoTL

Available at `https://trust.siros.org/`

## License

See [LICENSE](LICENSE).
