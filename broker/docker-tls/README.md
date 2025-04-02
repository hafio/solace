# Solace PubSub+ Software Broker (Standalone) via Docker with SSL/TLS

This project has the example of spinning up a Solace PubSub+ Software Broker on Docker along with SSL/TLS already setup.

Refer to `docker-compose.yaml` for more information.

Refer to [Configuration Keys](https://docs.solace.com/Software-Broker/Configuration-Keys-Reference.htm) for list of available configurations exposed to environment variables.

Refer to https://solace.com/products/event-broker/software/getting-started/ for more information.

# SSL/TLS Certificate

Refer to [this project](https://github.com/hafio/solace-psg/tree/main/ssl-certs) to generate SSL certificates.

`server.crt` must consist of the following content:
1. Server Certificate in PEM format
2. Server Key
3. Root Certificate in PEM format
4. Intermediate Certificate in PEM format (optional)

> The file must be put in a directory that is not under `/var/lib/solace` or `/usr/sw/jail` (`jail` maps to `solace`).
> The common/usual practice is for `server.crt` to be placed inside `/run/secrets` as per Solace documentation

# Port Redirection

It is a good security measure to disable plain-text HTTP port by commenting out the corresponding line for the plain-text HTTP Port (container port 8080). 

Alternatively, you can enable `HTTP` -> `HTTPS` redirection in the broker using the below environment variables:
- `webmanager_redirecthttp_enable`
- `webmanager_redirecthttp_overridetlsport`

Redirected port should match the exposed `HTTPS` port in `docker-compose.yaml`

# Storage

The example uses a local folder `storage-group` to provide persistent storage to the broker.

You can use a volume as an alternative.