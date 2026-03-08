# Solace PubSub+ Connector for IBM MQ — Configuration Guide

> **Complete reference** for every key and value available in the connector's `application.yml`.
>
> **Docker image:** `solace/solace-pubsub-connector-ibmmq:2.9.12`

---

## Table of Contents

- [YAML & Spring Boot Essentials (For Non-Spring Users)](#yaml--spring-boot-essentials-for-non-spring-users)
- [Configuration Overview (Tree Map)](#configuration-overview-tree-map)
- [1. Solace Event Broker Connection](#1-solace-event-broker-connection)
- [2. IBM MQ Connection](#2-ibm-mq-connection)
- [3. Spring Cloud Stream — Binders](#3-spring-cloud-stream--binders)
- [4. Spring Cloud Stream — Bindings (Workflows)](#4-spring-cloud-stream--bindings-workflows)
- [5. JMS Binder Options](#5-jms-binder-options)
- [6. JMS Binding-Level Options (Consumer & Producer)](#6-jms-binding-level-options-consumer--producer)
- [7. Solace Connector — Workflow Configuration](#7-solace-connector--workflow-configuration)
- [8. Solace Connector — Security](#8-solace-connector--security)
- [9. Solace Connector — Management & Leader Election](#9-solace-connector--management--leader-election)
- [10. Spring SSL Bundles](#10-spring-ssl-bundles)
- [11. Spring Actuator / Management Endpoint](#11-spring-actuator--management-endpoint)
- [12. Logging](#12-logging)
- [13. JVM System Properties](#13-jvm-system-properties)
- [14. Environment Variable Overrides](#14-environment-variable-overrides)
- [15. Spring Profiles & Config Locations](#15-spring-profiles--config-locations)

---

## YAML & Spring Boot Essentials (For Non-Spring Users)

If you're not familiar with Spring Boot, read this section carefully before editing `application.yml`.

### Relaxed Binding (kebab-case vs camelCase)

Spring Boot uses **relaxed binding**, meaning these are all **equivalent**:

| Format | Example |
|---|---|
| **kebab-case** (recommended) | `client-username` |
| camelCase | `clientUsername` |
| snake_case | `client_username` |
| UPPER_SNAKE_CASE | `CLIENT_USERNAME` |

```yaml
# All four lines below are equivalent:
solace.java.client-username: myuser     # ✅ recommended
solace.java.clientUsername: myuser       # ✅ works
solace.java.client_username: myuser     # ✅ works
```

> [!IMPORTANT]
> **Exception:** Keys inside `api-properties` and `additional-properties` are **NOT** relaxed-bound. They are passed verbatim to the underlying Solace/IBM MQ APIs.
> For example, you **must** write `SSL_VALIDATE_CERTIFICATE`, not `ssl-validate-certificate`.

### YAML Indentation

YAML uses **spaces only** (never tabs). Indentation defines the hierarchy:

```yaml
spring:
  cloud:           # 2 spaces = child of "spring"
    stream:        # 4 spaces = child of "cloud"
      binders:     # 6 spaces = child of "stream"
```

### Property Placeholders (`${}`)

Spring Boot resolves `${VAR_NAME}` from environment variables at startup:

```yaml
client-password: ${SOLACE1_PASSWORD:changeme}
#                  ^^^^^^^^^^^^^^^^^ ^^^^^^^^^
#                  env variable name  default if env variable is not set
```

The `:changeme` part is the **default value** used when the environment variable is absent.

### Property Precedence (Highest → Lowest)

When the same property is set in multiple places, Spring Boot uses this priority:

1. **Command-line arguments** (`--property=value`)
2. **Environment variables** (`SPRING_CLOUD_STREAM_...`)
3. **`application.yml` in external config dir** (`/app/external/spring/config/`)
4. **`application.yml` in classpath** (inside the JAR)

### Converting YAML Keys to Environment Variables

Spring Boot converts nested YAML keys to environment variables using these rules:

| Rule | Example |
|---|---|
| Replace `.` with `_` | `spring.cloud.stream` → `SPRING_CLOUD_STREAM` |
| Replace `-` with `_` | `client-username` → `CLIENT_USERNAME` |
| Uppercase everything | `solace.java.host` → `SOLACE_JAVA_HOST` |
| List indices use `_N_` | `users[0].name` → `USERS_0_NAME` |

```bash
# YAML:  solace.connector.security.users[0].name: healthcheck
# Env:
SOLACE_CONNECTOR_SECURITY_USERS_0_NAME=healthcheck
```

### The `undefined` Binder

Every Solace connector configuration **must** include an `undefined` binder:

```yaml
spring.cloud.stream.binders:
  undefined:
    type: undefined
```

This is required for internal use by the connector framework. **Do not remove it.**

### Single Binder vs Multi-Binder Syntax

When connecting to **one** Solace broker + **one** IBM MQ QM, use single-binder syntax:

```yaml
solace:
  java:
    host: tcp://localhost:55555
ibm:
  mq:
    queue-manager: QM1
```

When connecting to **multiple** systems, **all** binder config must move under `spring.cloud.stream.binders.<name>.environment`:

```yaml
spring:
  cloud:
    stream:
      binders:
        solace1:
          type: solace
          environment:
            solace:
              java:
                host: tcp://broker-1:55555
        jms1:
          type: jms
          environment:
            ibm:
              mq:
                queue-manager: QM1
```

> [!CAUTION]
> **Do NOT** mix single-binder (`solace.java.*` at root) and multi-binder (`spring.cloud.stream.binders.*`) syntax. Use one or the other.

---

## Configuration Overview (Tree Map)

```
application.yml
├── spring
│   ├── ssl.bundle.jks.*                      # Trust store definitions (Section 10)
│   └── cloud.stream
│       ├── binders.<name>                    # Binder definitions (Section 3)
│       │   ├── type: (solace | jms)
│       │   └── environment
│       │       ├── solace.java.*              # Solace connection (Section 1)
│       │       ├── ibm.mq.*                   # IBM MQ connection (Section 2)
│       │       └── jms-binder.*               # JMS binder options (Section 5)
│       ├── bindings.<input|output>-<N>        # Workflow data paths (Section 4)
│       └── jms.bindings.<name>.consumer|producer  # JMS binding options (Section 6)
│
├── solace.connector
│   ├── workflows.<N>.*                        # Workflow config (Section 7)
│   ├── default.workflow.*                     # Default workflow config (Section 7)
│   ├── security.*                             # Auth/users (Section 8)
│   └── management.*                           # Leader election (Section 9)
│
├── management.*                               # Spring Actuator (Section 11)
└── logging.*                                  # Log levels (Section 12)
```

---

## 1. Solace Event Broker Connection

**Prefix:** `solace.java.*`
(Under `spring.cloud.stream.binders.<name>.environment.solace.java.*` in multi-binder mode)

### Core Connection Properties

| Key | Type | Default | Description |
|---|---|---|---|
| `host` | String | `tcp://localhost:55555` | Broker URL. Use `tcps://` for TLS. Comma-separated for HA: `tcps://host1:55443,tcps://host2:55443` |
| `msg-vpn` | String | `default` | Message VPN name |
| `client-username` | String | `default` | Client username for authentication |
| `client-password` | String | `default` | Client password |
| `client-name` | String | _(auto)_ | Client name identifier. Auto-generated if omitted |
| `connect-retries` | int | `-1` | Number of times to retry connecting. `-1` = retry forever |
| `reconnect-retries` | int | `-1` | Number of times to retry reconnecting after disconnect. `-1` = retry forever |
| `connect-retries-per-host` | int | `0` | Number of connection retries per host before moving to the next host in the list |
| `reconnect-retry-wait-in-millis` | int | `3000` | Wait time (ms) between reconnection attempts |

### Solace API Properties (`api-properties`)

**Prefix:** `solace.java.api-properties.*`

These are passed **verbatim** to the Solace JCSMP API. Keys must match [JCSMPProperties constants](https://docs.solace.com/API-Developer-Online-Ref-Documentation/java/constant-values.html) exactly (UPPER_SNAKE_CASE).

| Key | Type | Default | Description |
|---|---|---|---|
| `SSL_VALIDATE_CERTIFICATE` | boolean | `true` | Validate the broker's server certificate |
| `SSL_VALIDATE_CERTIFICATE_DATE` | boolean | `true` | Validate the certificate's expiry date |
| `SSL_TRUST_STORE` | String | _(none)_ | Absolute path to JKS trust store file |
| `SSL_TRUST_STORE_PASSWORD` | String | _(none)_ | Password for the trust store |
| `SSL_CIPHER_SUITES` | String | _(all)_ | Comma-separated list of allowed TLS cipher suites |
| `SSL_KEY_STORE` | String | _(none)_ | Path to client key store (for mutual TLS) |
| `SSL_KEY_STORE_PASSWORD` | String | _(none)_ | Password for the client key store |
| `SSL_KEY_STORE_FORMAT` | String | `JKS` | Key store format (`JKS`, `PKCS12`) |
| `SSL_TRUST_STORE_FORMAT` | String | `JKS` | Trust store format |
| `SSL_EXCLUDED_PROTOCOLS` | String | _(none)_ | Comma-separated list of TLS protocols to exclude |
| `REAPPLY_SUBSCRIPTIONS` | boolean | `false` | Re-apply topic subscriptions after reconnect |
| `GENERATE_SEND_TIMESTAMPS` | boolean | `false` | Include send timestamps in published messages |
| `GENERATE_RCV_TIMESTAMPS` | boolean | `false` | Include receive timestamps |
| `GENERATE_SEQUENCE_NUMBERS` | boolean | `false` | Include sequence numbers in published messages |
| `PUB_ACK_WINDOW_SIZE` | int | `1` | Number of messages that can be published without acknowledgment |
| `SUB_ACK_WINDOW_SIZE` | int | `255` | Flow control: number of messages the broker can send before waiting for ack |
| `CLIENT_CHANNEL_PROPERTIES.keepAliveIntervalInMillis` | int | `3000` | Keep-alive interval (ms) |
| `CLIENT_CHANNEL_PROPERTIES.connectTimeoutInMillis` | int | `30000` | Connection timeout (ms) |
| `CLIENT_CHANNEL_PROPERTIES.compressionLevel` | int | `0` | Compression level (0–9, 0 = off) |

> [!NOTE]
> `api-properties` keys take the form `PROPERTY_NAME` (the JCSMP constant name). Sub-properties use dot notation, e.g. `CLIENT_CHANNEL_PROPERTIES.keepAliveIntervalInMillis`.
> Direct `solace.java.*` properties (like `host`) **take precedence** over equivalent `api-properties`.

**Example:**

```yaml
solace:
  java:
    host: tcps://broker.example.com:55443
    msg-vpn: production
    client-username: connector-user
    client-password: ${SOLACE_PASSWORD}
    connect-retries: -1
    reconnect-retries: -1
    api-properties:
      SSL_VALIDATE_CERTIFICATE: true
      SSL_TRUST_STORE: /app/external/classpath/truststores/solace-truststore.jks
      SSL_TRUST_STORE_PASSWORD: ${SOLACE_TRUSTSTORE_PASSWORD}
      REAPPLY_SUBSCRIPTIONS: true
      CLIENT_CHANNEL_PROPERTIES.keepAliveIntervalInMillis: 3000
```

---

## 2. IBM MQ Connection

**Prefix:** `ibm.mq.*`
(Under `spring.cloud.stream.binders.<name>.environment.ibm.mq.*` in multi-binder mode)

### Core Connection Properties

| Key | Type | Default | Description |
|---|---|---|---|
| `queue-manager` | String | _(required)_ | Queue Manager name |
| `channel` | String | _(required)_ | Server-connection channel name |
| `conn-name` | String | _(required)_ | Connection name in format `hostname(port)`. Multiple: `host1(1414),host2(1414)` |
| `user` | String | _(none)_ | Username to authenticate with MQ |
| `password` | String | _(none)_ | Password to authenticate with MQ |
| `ssl-bundle` | String | _(none)_ | Name of a Spring SSL Bundle for TLS (see [Section 10](#10-spring-ssl-bundles)) |

### Additional Properties (`additional-properties`)

**Prefix:** `ibm.mq.additional-properties.*`

Key-value pairs passed to the IBM MQ JMS connection. Keys can be the real string (often starting with `XMSC`) or the constant name from [WMQConstants](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=jms-wmqconstants).

| Key | Type | Description |
|---|---|---|
| `WMQ_SSL_CIPHER_SUITE` | String | The TLS cipher suite for the connection (JCE naming, e.g. `TLS_RSA_WITH_AES_256_CBC_SHA256`) |
| `WMQ_SSL_PEER_NAME` | String | Distinguished Name (DN) filter to verify the QM certificate. Empty string `""` = skip verification |
| `WMQ_CLIENT_RECONNECT_OPTIONS` | String | Client reconnect behavior (`MQCNO_RECONNECT`, `MQCNO_RECONNECT_Q_MGR`, etc.) |

> [!WARNING]
> IBM MQ uses **IBM cipher spec names** by default, but the connector's JVM uses JCE names. You **must** set the JVM property `-Dcom.ibm.mq.cfg.useIBMCipherMappings=false` to use standard JCE cipher names (like `TLS_RSA_WITH_AES_256_CBC_SHA256`). See [Section 13](#13-jvm-system-properties).

**Example (Manual):**

```yaml
ibm:
  mq:
    queue-manager: QM1
    channel: DEV.APP.SVRCONN
    conn-name: ibmmq-host.example.com(1414)
    user: ${IBMMQ_USER}
    password: ${IBMMQ_PASSWORD}
    ssl-bundle: ibmmq-bundle              # References Section 10
    additional-properties:
      WMQ_SSL_CIPHER_SUITE: TLS_RSA_WITH_AES_256_CBC_SHA256
      WMQ_SSL_PEER_NAME: "CN=ibmmq-host.example.com, O=MyOrg, C=US"
```

### JNDI Configuration (Alternative to Manual)

Instead of specifying connection properties directly, you can use JNDI to look up connection factories.

**Prefix:** `jms-binder.jndi.*`
(Under `spring.cloud.stream.binders.<name>.environment.jms-binder.jndi.*` in multi-binder mode)

| Key | Type | Description |
|---|---|---|
| `context.<property>` | String | Standard JNDI context properties (e.g. `java.naming.factory.initial`, `java.naming.provider.url`) |
| `connection-factory.name` | String | JNDI name of the connection factory to look up |
| `connection-factory.user` | String | Username to authenticate with the QM via the looked-up factory |
| `connection-factory.password` | String | Password for the QM authentication |

> [!IMPORTANT]
> JNDI connection factories **must not** specify a `clientID`, as this prevents producer bindings from connecting.

**Example (JNDI):**

```yaml
jms-binder:
  jndi:
    context:
      java.naming.factory.initial: com.sun.jndi.fscontext.RefFSContextFactory
      java.naming.provider.url: file:/path/to/bindings/file
    connection-factory:
      name: myConnectionFactory
      user: app
      password: passw0rd
```

---

## 3. Spring Cloud Stream — Binders

**Prefix:** `spring.cloud.stream.binders.*`

Binders define connections to external systems. Each binder has a unique name.

```yaml
spring:
  cloud:
    stream:
      binders:
        <binder-name>:
          type: (solace | jms | undefined)
          environment:
            # ... connection properties go here
```

| Key | Type | Values | Description |
|---|---|---|---|
| `<name>.type` | String | `solace`, `jms`, `undefined` | Type of binder. `undefined` is required for internal use |
| `<name>.environment.*` | Map | _(varies)_ | Binder-specific configuration. All properties from [Section 1](#1-solace-event-broker-connection) (for `solace`) or [Section 2](#2-ibm-mq-connection) (for `jms`) go here |

> [!NOTE]
> You must always include the `undefined` binder:
> ```yaml
> undefined:
>   type: undefined
> ```

---

## 4. Spring Cloud Stream — Bindings (Workflows)

**Prefix:** `spring.cloud.stream.bindings.*`

Bindings define the **data flow paths** between source and target systems. Each workflow is defined by a pair of `input-<N>` and `output-<N>` bindings.

| Key | Type | Description |
|---|---|---|
| `input-<N>.destination` | String | Source destination name (queue name, topic string, table name, etc.) |
| `input-<N>.binder` | String | Name of the binder to use for the source (must match a name in `binders`) |
| `output-<N>.destination` | String | Target destination name |
| `output-<N>.binder` | String | Name of the binder to use for the target |

- `<N>` is a **workflow ID** from `0` to `19` (maximum 20 workflows)
- The connector **does not** auto-provision queues. They must exist on the broker before starting

**Example:**

```yaml
spring:
  cloud:
    stream:
      bindings:
        # Workflow 0: IBM MQ → Solace
        input-0:
          destination: MQ.SOURCE.QUEUE
          binder: jms1
        output-0:
          destination: solace/events/from-mq
          binder: solace1

        # Workflow 1: Solace → IBM MQ
        input-1:
          destination: solace/queue/to-mq
          binder: solace1
        output-1:
          destination: MQ.TARGET.QUEUE
          binder: jms1
```

---

## 5. JMS Binder Options

**Prefix:** `jms-binder.*`
(Under `spring.cloud.stream.binders.<name>.environment.jms-binder.*` in multi-binder mode)

These are binder-level settings that apply to the entire IBM MQ JMS connection.

| Key | Type | Default | Description |
|---|---|---|---|
| `health-check.interval` | long | `10000` | Interval (ms) between reconnection attempts while health status is `RECONNECTING` |
| `healthcheck.reconnectattempts-until-down` | long | `10` | Number of reconnect attempts before binder transitions from `RECONNECTING` to `DOWN`. `0` = unlimited (never transitions to `DOWN`) |

**Example:**

```yaml
jms-binder:
  health-check:
    interval: 15000
  healthcheck:
    reconnectattempts-until-down: 20
```

---

## 6. JMS Binding-Level Options (Consumer & Producer)

### Consumer Options

**Prefix:** `spring.cloud.stream.jms.bindings.<bindingName>.consumer.*`
**Default prefix (applies to all JMS consumers):** `spring.cloud.stream.jms.default.consumer.*`

| Key | Type | Values | Default | Description |
|---|---|---|---|---|
| `batch-max-size` | int | `>= 1` | `255` | Max messages per batch. Set to `1` to disable batching. If any message in a batch fails, **all messages in the batch are rejected** |
| `transacted` | boolean | `true` / `false` | `true` | Receive messages within a local JMS transaction. Set to `false` to improve performance, especially when `batch-max-size=1` |
| `destination-type` | String | `queue` / `topic` / `unknown` | `unknown` | Type of JMS destination. `queue` = physical queue (no JNDI lookup). `topic` = physical topic (requires `durable-subscription-name`). `unknown` = JNDI name lookup |
| `durable-subscription-name` | String | any | _(none)_ | Name of a shared durable subscription. **Required** when `destination-type` is `topic`. The subscription is auto-created if it doesn't exist |

**Standard Spring Cloud Stream consumer prefix:** `spring.cloud.stream.bindings.<bindingName>.consumer.*`

| Key | Type | Default | Description |
|---|---|---|---|
| `concurrency` | int | `1` | Number of concurrent consumers to create |

> [!TIP]
> For non-durable topic subscriptions (messages received only while connected), set `destination-type: topic` and do **not** provide a `durable-subscription-name`.

**Example:**

```yaml
spring:
  cloud:
    stream:
      jms:
        bindings:
          input-0:
            consumer:
              destination-type: queue
              batch-max-size: 100
              transacted: false
          input-4:
            consumer:
              destination-type: topic
              # Omit durable-subscription-name for non-durable
      bindings:
        input-0:
          consumer:
            concurrency: 3
```

### Producer Options

**Prefix:** `spring.cloud.stream.jms.bindings.<bindingName>.producer.*`
**Default prefix (applies to all JMS producers):** `spring.cloud.stream.jms.default.producer.*`

| Key | Type | Values | Default | Description |
|---|---|---|---|---|
| `destination-type` | String | `queue` / `topic` / `unknown` | `unknown` | Type of JMS destination for publishing. `queue` = physical queue. `topic` = physical topic. `unknown` = JNDI lookup |
| `transacted` | boolean | `true` / `false` | `true` | Publish messages within a JMS local transaction. Provides duplicate protection on producer failures |

**Example:**

```yaml
spring:
  cloud:
    stream:
      jms:
        bindings:
          output-0:
            producer:
              destination-type: queue
              transacted: true
```

---

## 7. Solace Connector — Workflow Configuration

**Per-workflow prefix:** `solace.connector.workflows.<N>.*`
**Default prefix (applies to all workflows):** `solace.connector.default.workflow.*`

| Key | Type | Values | Default | Description |
|---|---|---|---|---|
| `enabled` | boolean | `true` / `false` | `false` | Enable or disable this workflow |
| `transform.source-payload.content-type` | String | See below | `application/vnd.solace.micro-integration.unspecified` | How to interpret the source message payload |
| `transform.target-payload.content-type` | String | See below | `application/vnd.solace.micro-integration.unspecified` | How to format the target message payload |
| `transform.expressions[<index>].transform` | String | expression | _(none)_ | Ordered list of transform expressions to apply to messages. See [Mapping Message Headers and Payloads](https://docs.solace.com/Micro-Integrations/Self-Managed/Message-transforms.htm) |
| `acknowledgment.publish-async` | boolean | `true` / `false` | `false` | Process publisher acknowledgments asynchronously. Both consumer and producer bindings must support this mode |
| `acknowledgment.back-pressure-threshold` | int | `-1` or `>= 1` | `-1` | Max outstanding unacknowledged messages. `-1` = disabled. Consumption pauses when threshold is reached |
| `acknowledgment.publish-timeout` | int | `>= 1` | `600000` | Max time (ms) to wait for async publisher acks. `-1` = wait indefinitely |

**Content type values:**

| Value | Description |
|---|---|
| `application/vnd.solace.micro-integration.unspecified` | Pass-through, no interpretation |
| `application/json` | Interpret payload as JSON (enables JSON-based transforms) |

**Example:**

```yaml
solace:
  connector:
    workflows:
      0:
        enabled: true
        transform:
          source-payload:
            content-type: application/json
          target-payload:
            content-type: application/json
          expressions:
            - transform: "setPayload(payload.order)"
        acknowledgment:
          publish-async: true
          back-pressure-threshold: 1000
          publish-timeout: 30000
      1:
        enabled: true
    default:
      workflow:
        acknowledgment:
          publish-async: false
```

---

## 8. Solace Connector — Security

**Prefix:** `solace.connector.security.*`

| Key | Type | Default | Description |
|---|---|---|---|
| `enabled` | boolean | `true` | Enable HTTP Basic auth on management endpoints. Set to `false` to allow unauthenticated access |
| `users[<index>].name` | String | _(none)_ | Username for management endpoint access |
| `users[<index>].password` | String | _(none)_ | Password for the user |
| `users[<index>].roles` | List\<String\> | `[]` (read-only) | Roles: omit for read-only (GET only), add `admin` for read/write (GET + POST) |

> [!IMPORTANT]
> `solace.connector.security.users` is a **list**. When defined in multiple sources (YAML files, env vars), the entire list is **replaced**, not merged. Define all users in one place.

**Example (YAML):**

```yaml
solace:
  connector:
    security:
      enabled: true
      users:
        - name: healthcheck
          password: ${HEALTHCHECK_PASSWORD}
        - name: admin
          password: ${ADMIN_PASSWORD}
          roles:
            - admin
```

**Example (Environment Variables):**

```bash
SOLACE_CONNECTOR_SECURITY_USERS_0_NAME=healthcheck
SOLACE_CONNECTOR_SECURITY_USERS_0_PASSWORD=secret
SOLACE_CONNECTOR_SECURITY_USERS_1_NAME=admin
SOLACE_CONNECTOR_SECURITY_USERS_1_PASSWORD=admin-secret
SOLACE_CONNECTOR_SECURITY_USERS_1_ROLES_0=admin
```

---

## 9. Solace Connector — Management & Leader Election

**Prefix:** `solace.connector.management.*`

### Leader Election Mode

| Key | Type | Values | Default | Description |
|---|---|---|---|---|
| `leader-election.mode` | enum | `standalone` / `active_active` / `active_standby` | `standalone` | Redundancy mode |

| Mode | Behavior |
|---|---|
| `standalone` | Single instance, no leader election |
| `active_active` | All instances in the cluster are active simultaneously |
| `active_standby` | One leader is active; others are standby. Requires a management session and queue |

### Active-Standby Configuration

Required when `leader-election.mode` is `active_standby`:

| Key | Type | Default | Description |
|---|---|---|---|
| `queue` | String | _(none)_ | Management queue name (must be **exclusive** access type) |
| `session.host` | String | _(none)_ | Solace management broker host |
| `session.msg-vpn` | String | _(none)_ | Management VPN name |
| `session.client-username` | String | _(none)_ | Management session username |
| `session.client-password` | String | _(none)_ | Management session password |
| `session.*` | _(any)_ | | Same interface as `solace.java.*` — all properties from [Section 1](#1-solace-event-broker-connection) are available |

### Failover Configuration

| Key | Type | Default | Description |
|---|---|---|---|
| `leader-election.fail-over.max-attempts` | int | `3` | Max retry attempts during failover |
| `leader-election.fail-over.back-off-initial-interval` | long | `1000` | Initial retry interval (ms) |
| `leader-election.fail-over.back-off-max-interval` | long | `10000` | Max retry interval (ms) |
| `leader-election.fail-over.back-off-multiplier` | double | `2.0` | Multiplier applied to retry interval between attempts |

**Example:**

```yaml
solace:
  connector:
    management:
      leader-election:
        mode: active_standby
        fail-over:
          max-attempts: 5
          back-off-initial-interval: 2000
      queue: connector-mgmt-queue
      session:
        host: tcps://mgmt-broker.example.com:55443
        msg-vpn: management-vpn
        client-username: mgmt-user
        client-password: ${MGMT_PASSWORD}
```

---

## 10. Spring SSL Bundles

**Prefix:** `spring.ssl.bundle.jks.*`

SSL Bundles define trust stores (and optionally key stores) that can be referenced by IBM MQ binders via the `ssl-bundle` property.

| Key | Type | Description |
|---|---|---|
| `<bundle-name>.truststore.location` | String | Absolute path to the JKS trust store file |
| `<bundle-name>.truststore.password` | String | Password for the trust store |
| `<bundle-name>.truststore.type` | String | Trust store type: `JKS`, `PKCS12` |
| `<bundle-name>.keystore.location` | String | Path to the client key store (for mTLS) |
| `<bundle-name>.keystore.password` | String | Password for the key store |
| `<bundle-name>.keystore.type` | String | Key store type: `JKS`, `PKCS12` |

**Example:**

```yaml
spring:
  ssl:
    bundle:
      jks:
        ibmmq1-bundle:
          truststore:
            location: /app/external/classpath/truststores/ibmmq1-truststore.jks
            password: ${IBMMQ1_TRUSTSTORE_PASSWORD}
            type: JKS
```

Then reference in the IBM MQ binder config:

```yaml
ibm:
  mq:
    ssl-bundle: ibmmq1-bundle
```

> [!NOTE]
> SSL Bundles are a **Spring Boot 3.1+** feature. Solace connectors version 2.3.0+ support this.

---

## 11. Spring Actuator / Management Endpoint

**Prefix:** `management.*`

| Key | Type | Default | Description |
|---|---|---|---|
| `server.port` | int | `8090` | Port for the management/actuator endpoint |
| `endpoints.web.exposure.include` | String | `health` | Comma-separated list of actuator endpoints to expose. Common: `health,info,metrics,leaderelection` |
| `endpoint.health.show-details` | String | `never` | Show health details: `never`, `when-authorized`, `always` |
| `info.build.enabled` | boolean | `true` | Include build info in the `/actuator/info` endpoint |

**Available actuator endpoints:**

| Endpoint | Path | Description |
|---|---|---|
| `health` | `/actuator/health` | Application health status |
| `info` | `/actuator/info` | Build version and metadata |
| `metrics` | `/actuator/metrics` | Micrometer metrics |
| `leaderelection` | `/actuator/leaderelection` | Leader election status (custom Solace endpoint) |

**Example:**

```yaml
management:
  server:
    port: 8090
  endpoints:
    web:
      exposure:
        include: health,info,metrics,leaderelection
  endpoint:
    health:
      show-details: always
```

---

## 12. Logging

**Prefix:** `logging.*`

Spring Boot uses [Logback](https://logback.qos.ch/) by default.

| Key | Type | Description |
|---|---|---|
| `level.root` | String | Root log level: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `OFF` |
| `level.<logger>` | String | Log level for specific packages/classes |

**Common loggers for this connector:**

| Logger | What It Logs |
|---|---|
| `com.solace` | Solace connector & binder internals |
| `com.solace.connector` | Connector-specific logic (workflows, transforms) |
| `com.solace.spring.cloud.stream.binder` | Solace Spring Cloud Stream binder |
| `com.ibm.mq` | IBM MQ client library |
| `org.springframework.cloud.stream` | Spring Cloud Stream framework |
| `org.springframework.jms` | Spring JMS |
| `org.springframework.boot.actuate` | Actuator endpoints |

**Example:**

```yaml
logging:
  level:
    root: INFO
    com.solace: DEBUG
    com.ibm.mq: WARN
    org.springframework.cloud.stream: INFO
```

---

## 13. JVM System Properties

Set via the `JDK_JAVA_OPTIONS` environment variable (or `JAVA_TOOL_OPTIONS`).

| Property | Value | Description |
|---|---|---|
| `-Dcom.ibm.mq.cfg.useIBMCipherMappings=false` | `false` | **Required** when using JCE cipher names (e.g. `TLS_RSA_WITH_AES_256_CBC_SHA256`) instead of IBM cipher spec names |
| `-Dcom.sun.net.ssl.checkRevocation=false` | `false` | Disable CRL/OCSP certificate revocation checking (dev only) |
| `-Djavax.net.ssl.trustStore=/path/to/truststore.jks` | path | JVM-level trust store (fallback for all SSL connections) |
| `-Djavax.net.ssl.trustStorePassword=changeit` | password | Password for the JVM-level trust store |
| `-Djavax.net.ssl.trustStoreType=JKS` | `JKS`/`PKCS12` | Trust store type |
| `-XX:ActiveProcessorCount=<N>` | int | Override detected CPU count (useful in containers) |
| `-Xmx<size>` | e.g. `2048m` | Max JVM heap size |
| `-Xms<size>` | e.g. `512m` | Initial JVM heap size |

**Example (Kubernetes env var):**

```yaml
env:
  - name: JDK_JAVA_OPTIONS
    value: >-
      -XX:ActiveProcessorCount=2
      -Xmx2048m
      -Dcom.ibm.mq.cfg.useIBMCipherMappings=false
```

---

## 14. Environment Variable Overrides

Any YAML property can be overridden via environment variables. This is the recommended approach for sensitive values.

**Conversion rules:**

```
spring.cloud.stream.binders.solace1.environment.solace.java.host
                          ↓
SPRING_CLOUD_STREAM_BINDERS_SOLACE1_ENVIRONMENT_SOLACE_JAVA_HOST
```

**Common environment variable overrides:**

| Env Variable | Overrides |
|---|---|
| `SOLACE_JAVA_HOST` | `solace.java.host` (single-binder only) |
| `SOLACE_JAVA_CLIENT_PASSWORD` | `solace.java.client-password` (single-binder only) |
| `IBM_MQ_USER` | `ibm.mq.user` (single-binder only) |
| `IBM_MQ_PASSWORD` | `ibm.mq.password` (single-binder only) |
| `MANAGEMENT_SERVER_PORT` | `management.server.port` |
| `LOGGING_LEVEL_ROOT` | `logging.level.root` |

> [!WARNING]
> In multi-binder mode, overriding deeply nested binder properties via env vars produces very long variable names. Use `${PLACEHOLDER}` references inside YAML instead:
> ```yaml
> client-password: ${SOLACE1_PASSWORD}
> ```

---

## 15. Spring Profiles & Config Locations

### Spring Profiles

Profiles let you maintain **environment-specific** configurations (dev, staging, production) in separate files.

| File | Active When |
|---|---|
| `application.yml` | Always loaded (base config) |
| `application-dev.yml` | Profile `dev` is active |
| `application-prod.yml` | Profile `prod` is active |

Activate a profile:

```bash
# Via environment variable
SPRING_PROFILES_ACTIVE=prod

# Via command line
--spring.profiles.active=prod
```

Properties in profile-specific files **override** the base `application.yml`.

### Config File Locations

The connector searches for config files in [Spring Boot's default locations](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config.files):

1. `classpath:/` and `classpath:/config/` (inside the JAR)
2. `./` and `./config/` (current working directory)

**To add an external config directory:**

```bash
--spring.config.additional-location=file:/app/external/spring/config/
```

**To exclusively use custom locations:**

```bash
--spring.config.location=optional:classpath:/,optional:classpath:/config/,file:/app/external/spring/config/
```

> [!TIP]
> Use Spring profiles rather than sub-directories to organize config files per environment:
> - ✅ `config/application-prod.yml`
> - ✅ `config/application-dev.yml`
> - ❌ `config/prod/application.yml`
> - ❌ `config/dev/application.yml`

---

## Quick Reference — Full Minimal Example

```yaml
# ---- Spring Cloud Stream ----
spring:
  cloud:
    stream:
      binders:
        solace1:
          type: solace
          environment:
            solace:
              java:
                host: tcps://broker.example.com:55443
                msg-vpn: default
                client-username: user
                client-password: ${SOLACE_PASSWORD}
                api-properties:
                  SSL_VALIDATE_CERTIFICATE: false

        jms1:
          type: jms
          environment:
            ibm:
              mq:
                queue-manager: QM1
                channel: DEV.APP.SVRCONN
                conn-name: mq-host.example.com(1414)
                user: ${MQ_USER}
                password: ${MQ_PASSWORD}

        undefined:
          type: undefined

      bindings:
        input-0:
          destination: MQ.SOURCE.QUEUE
          binder: jms1
        output-0:
          destination: solace/events/from-mq
          binder: solace1

# ---- Connector Workflows ----
solace:
  connector:
    workflows:
      0:
        enabled: true
    security:
      users:
        - name: healthcheck
          password: ${HEALTHCHECK_PASSWORD}

# ---- Management ----
management:
  server:
    port: 8090
  endpoints:
    web:
      exposure:
        include: health,info

# ---- Logging ----
logging:
  level:
    root: INFO
```

---

## Official Documentation Links

| Topic | URL |
|---|---|
| Connector Docker Hub | https://hub.docker.com/r/solace/solace-pubsub-connector-ibmmq |
| IBM MQ Connection Config | https://docs.solace.com/Micro-Integrations/Self-Managed/IBM-MQ/IBMMQ-Configuring-Connection-Details.htm |
| JMS Destination Types | https://docs.solace.com/Micro-Integrations/Self-Managed/IBM-MQ/IBMMQ-JMS-Destination-Types.htm |
| Solace Broker Connection | https://docs.solace.com/Micro-Integrations/Self-Managed/Event-Broker-Connection-Details.htm |
| Enabling Workflows | https://docs.solace.com/Micro-Integrations/Self-Managed/Enabling-Workflows.htm |
| Message Transforms | https://docs.solace.com/Micro-Integrations/Self-Managed/Message-transforms.htm |
| Security | https://docs.solace.com/Micro-Integrations/Self-Managed/Security.htm |
| Leader Election | https://docs.solace.com/Micro-Integrations/Self-Managed/Leader-Election.htm |
| Connector Configuration | https://docs.solace.com/Micro-Integrations/Self-Managed/Connector-Configuration.htm |
| Solace Java API Properties | https://docs.solace.com/API-Developer-Online-Ref-Documentation/java/constant-values.html |
| Spring Cloud Stream Docs | https://docs.spring.io/spring-cloud-stream/docs/current/reference/html/ |
| Spring Boot Externalized Config | https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config |
| IBM MQ WMQConstants | https://www.ibm.com/docs/en/ibm-mq/9.2?topic=jms-wmqconstants |
