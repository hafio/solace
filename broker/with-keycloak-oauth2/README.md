# Solace PubSub+ — OIDC / OAuth2 for Management Access via Keycloak

> Reference: https://docs.solace.com/Admin/Configuring-OAuth-for-Management-Access.htm

## Scope

Configures Keycloak users to authenticate against the **Solace management plane**
(Broker Manager web UI + SEMPv2 REST API).

> **NOT for SMF / AMQP / MQTT messaging clients connecting to a VPN.**

---

## Users and Access

| Keycloak User | Keycloak Group | JWT `groups` claim | Solace Access Level |
|---|---|---|---|
| `adminkeyclock` | `solace-admin` | `["solace-admin"]` | `admin` |
| `readonlykeyclock` | `solace-readonly` | `["solace-readonly"]` | `read-only` |

---

## Prerequisites

| Item | Value |
|---|---|
| Keycloak image | `quay.io/keycloak/keycloak:24.0.5` |
| Keycloak host (from broker container) | `host.docker.internal` |
| Keycloak port | `8080` (adjust to your mapping) |
| Realm | `solace` |
| Client ID | `solace-broker` |
| Client Secret | `solace-secret-change-me` ← **change this** |
| Solace version | PubSub+ Enterprise 10.x |

> **⚠️ Keycloak 24+ URLs — no `/auth/` prefix:**
> `http://host.docker.internal:8080/realms/solace/...`

> **⚠️ Solace oauth-profile name rule:**
> Only letters, numbers, underscores — use `keycloak_oidc`, not `keycloak-oidc`.

---

## How the Groups Claim Works

Keycloak is configured with **Groups** (not Realm Roles). The `solace-broker` client
has a `groups-mapper` protocol mapper (`oidc-group-membership-mapper`) that adds the
user's group memberships to the JWT as a `groups` array claim with `full.path: false`,
so the token contains `"solace-admin"` not `"/solace-admin"`.

Solace reads the `groups` claim and matches each value against the configured
`access-level` groups to determine the user's management access level.

---

## Step 1 — Start Keycloak

```bash
# Place docker-compose.yml and realm-export.json in the same directory
docker compose up -d

# Watch for successful import
docker compose logs keycloak | grep -i "realm\|import"
# Expected: Realm 'solace' imported
```

---

## Step 2 — Verify JWT Claims Before Touching the Broker

```bash
TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/solace/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=solace-broker" \
  -d "client_secret=solace-secret-change-me" \
  -d "username=adminkeyclock" \
  -d "password=Admin@1234" \
  | jq -r '.access_token')

echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq '{sub, groups, iss}'
```

Expected:
```json
{
  "sub": "<keycloak-user-uuid>",
  "groups": ["solace-admin"],
  "iss": "http://host.docker.internal:8080/realms/solace"
}
```

If `groups` is missing: Keycloak Admin → realm **solace** → Clients → `solace-broker`
→ Mappers → confirm `groups-mapper` exists with protocol mapper type
`Group Membership` and claim name `groups`.

---

## Step 3 — Solace CLI: Create the OAuth Profile

Access the broker CLI (`cli` inside the container or SSH to the broker).

```
enable
configure
```

### 3a — Create and enter the profile
```
create authentication oauth-profile keycloak_oidc
authentication oauth-profile keycloak_oidc
```

### 3b — Identity and claim settings
```
    display-name "Keycloak OIDC"
    client-id "solace-broker"
    client-secret "solace-secret-change-me"
    issuer "http://host.docker.internal:8080/realms/solace"
    username-claim-name "sub"
    access-level-groups-claim-name "groups"
    prompt-for-new-session "select_account"
```

### 3c — Discovery endpoint (auto-discovers all other endpoints)
```
    endpoints
        discovery "http://host.docker.internal:8080/realms/solace/.well-known/openid-configuration"
        exit
```

> **Production note:** Solace requires `https://` for all endpoints.
> See the [HTTPS Workaround](#https-workaround) section for local dev on plain HTTP.

### 3d — Allowed host (must match the Broker Manager browser URL exactly)
```
    client
        create allowed-host <SOLACE_MANAGER_HOST>:<PORT>
        exit
```

> e.g. `192.168.1.50:8080` — the `host:port` users type in their browser.
> Incorrect value = OAuth redirect failures.

### 3e — Map Keycloak groups to Solace access levels
```
    access-level
        create group solace-admin
        group solace-admin
            global-access-level admin
            exit
        create group solace-readonly
        group solace-readonly
            global-access-level read-only
            exit
        exit
```

> Group names are **case-sensitive** and must match the JWT `groups` claim values exactly.

### 3f — Enable and set as default
```
    no shutdown
    exit

oauth-profile-default keycloak_oidc
```

Save:
```
end
write memory
```

---

## Step 4 — Verify on the Broker

```
show authentication oauth-profile keycloak_oidc
show authentication oauth-profile keycloak_oidc access-level
```

---

## Step 5 — Log In via Broker Manager

Navigate to `http://<SOLACE_HOST>:8080`. A **"Keycloak OIDC"** button appears on
the login page. Click it to authenticate via Keycloak.

Test SEMPv2 with a bearer token:
```bash
TOKEN=$(curl -s -X POST \
  "http://localhost:8080/realms/solace/protocol/openid-connect/token" \
  -d "grant_type=password" -d "client_id=solace-broker" \
  -d "client_secret=solace-secret-change-me" \
  -d "username=adminkeyclock" -d "password=Admin@1234" \
  -H "Content-Type: application/x-www-form-urlencoded" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" \
  http://<SOLACE_HOST>:8080/SEMP/v2/config/about/api
```

---

## HTTPS Workaround

For local dev where Keycloak is on plain HTTP, add an nginx TLS proxy to
`docker-compose.yml`:

```yaml
  nginx:
    image: nginx:alpine
    ports:
      - "8443:443"
    volumes:
      - ./nginx-keycloak.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - keycloak
    networks:
      - solace-auth
```

`nginx-keycloak.conf`:
```nginx
server {
    listen 443 ssl;
    ssl_certificate     /etc/nginx/certs/keycloak.crt;
    ssl_certificate_key /etc/nginx/certs/keycloak.key;
    location / {
        proxy_pass http://keycloak:8080;
        proxy_set_header Host              $host;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

Generate a self-signed cert:
```bash
mkdir certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/keycloak.key -out certs/keycloak.crt \
  -subj "/CN=host.docker.internal"
```

Then use `https://host.docker.internal:8443/realms/solace/...` in the Solace
`discovery` endpoint and `issuer` settings.

---

## Architecture Summary

```
adminkeyclock / readonlykeyclock
    │
    ├─► Keycloak (realm: solace) — interactive or password grant
    │     JWT contains:
    │       sub    = "<user-uuid>"      ← session username in Solace
    │       groups = ["solace-admin"]   ← determines management access level
    │       iss    = "http://host.docker.internal:8080/realms/solace"
    │
    └─► Broker Manager / SEMPv2  (Bearer token or browser OAuth flow)
            │
            ├─ Validates JWT signature via JWKS (auto-discovered)
            ├─ Verifies issuer claim
            ├─ Reads sub       → session username
            ├─ Reads groups[0] → "solace-admin"
            └─ Maps to group "solace-admin" → global-access-level admin

  ──────────────────────────────────────────────────────
  SMF / AMQP / MQTT application clients are NOT affected.
  ──────────────────────────────────────────────────────
```

---

## Adding More Groups

To add additional access levels (e.g. read-write), create the group in Keycloak
and add the corresponding entry in Solace:

**Keycloak** (`realm-export.json` or Admin Console):
```json
{ "name": "solace-readwrite", "path": "/solace-readwrite" }
```

**Solace CLI:**
```
authentication oauth-profile keycloak_oidc
    access-level
        create group solace-readwrite
        group solace-readwrite
            global-access-level read-write
            exit
        exit
    exit
end
write memory
```

Available `global-access-level` values: `admin` | `read-write` | `read-only` | `none`

---

## Important Notes

1. **Groups not Roles**: Keycloak uses Groups with `oidc-group-membership-mapper`. Realm Roles are not used.
2. **`full.path: false`**: JWT emits `solace-admin`, not `/solace-admin`. Solace group names must match without the slash.
3. **`sub` claim**: Solace sessions display the user's Keycloak UUID, not the username.
4. **`allowed-host`** must match the exact `host:port` in the browser URL for Broker Manager.
5. **HTTPS required** in production for all OAuth endpoints.
6. **Temporary passwords**: Users reset at `http://localhost:8080/realms/solace/account`.
7. **Token expiry**: 300 seconds. Broker Manager handles refresh automatically; SEMP API clients must refresh manually.
