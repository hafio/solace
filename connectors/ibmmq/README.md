# Solace-IBMMQ Connector

This project captures the steps to setup Solace <> IBM MQ Connector.

# Steps

1. Download container image from products.solace.com
2. Download `release` zip file
3. Read `libs/README.md` in release zip file to get list of jar libraries to download.
   - Can follow instructions inside to download/retrieve all libraries, or use jar files I added in `libs` github folder.
4. Update `config/application.yml` accordingly to reflect queues and topics workflow
5. Execute `docker-compose up -d`

# Jar libraries required
> Please make sure to download the correct version according to your release notes.
- https://mvnrepository.com/artifact/org.bouncycastle/bcpkix-jdk18on
- https://mvnrepository.com/artifact/org.bouncycastle/bcutil-jdk18on
- https://mvnrepository.com/artifact/org.bouncycastle/bcprov-jdk18on
- https://mvnrepository.com/artifact/com.ibm.mq/com.ibm.mq.allclient
- https://mvnrepository.com/artifact/com.ibm.mq/com.ibm.mq.jakarta.client
- https://mvnrepository.com/artifact/com.fasterxml.jackson.core/jackson-annotations
- https://mvnrepository.com/artifact/com.fasterxml.jackson.core/jackson-core
- https://mvnrepository.com/artifact/com.fasterxml.jackson.core/jackson-databind
- https://mvnrepository.com/artifact/jakarta.jms/jakarta.jms-api
- https://mvnrepository.com/artifact/org.json/json

# Building complete image

If you need to use a complete image instead, create `Dockerfile` with the below content:
```Dockerfile
FROM solace/solace-pubsub-connector-ibmmq:2.9.0
COPY libs /app/external/libs
```
> MQ Connector image v2.9.0 (check solace website for latest version) imported locally to `solace/solace-pubsub-connector-ibmmq:2.9.0` <br>
> All above libraries are in `libs` folder relatively to `Dockerfile`

Execute
```
docker build -t sol-mq-conn:2.9.0 .
```
> take note of the **dot** at the end. It is mandatory

The image `sol-mq-conn:2.9.0` should be available locally. You can export / save as required.
