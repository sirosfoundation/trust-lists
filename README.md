# trust-lists

Published [ETSI TS 119 602](https://www.etsi.org/deliver/etsi_ts/119600_119699/119602/)
Lists of Trusted Entities (LoTE) and Trust Status Lists (TSL) for the EUDI wallet ecosystem.

**Live site:** [trust.siros.org](https://trust.siros.org)

## How it works

1. Trust list source data lives under `lists/` as YAML + certificates
2. Pull requests add, update, or remove trusted entities — reviewed before merge
3. On merge to `main`, GitHub Actions runs
   [g119612/tsl-tool](https://github.com/sirosfoundation/g119612) to generate
   and sign LoTE JSON documents
4. Signed output is deployed to GitHub Pages at `trust.siros.org`

## Repository structure

```
lists/
  <instance>/                   # One directory per trust list
    scheme.yaml                 # LoTE scheme metadata
    entities/
      <entity>/                 # One directory per trusted entity
        entity.yaml             # Entity metadata
        cert.pem                # X.509 certificate (optional)
        key.jwk                 # JWK public key (optional)

pipelines/                      # Custom pipelines (e.g. EU LOTL fetch)

static/                         # Assets for the landing page
templates/                      # HTML templates
scripts/                        # Build helpers
```

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

## Signing

Trust lists are signed using JWS (JSON Web Signature) via a PKCS#11 interface.

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

## Output

Each trust list produces:

- `lote-<territory>.json` — Unsigned LoTE JSON
- `lote-<territory>.json.jws` — JWS-signed LoTE

Available at `https://trust.siros.org/lote-<territory>.json.jws`

## License

See [LICENSE](LICENSE).
