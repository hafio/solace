# Solace-IBMMQ Connector

This project captures the steps to setup Solace <> IBM MQ Connector.

# Steps

1. Download container image from products.solace.com
2. Download `release` zip file
3. Read `libs/README.md` in release zip file to get list of jar libraries to download.
   - Can follow instructions inside to download/retrieve all libraries, or use jar files I added in `libs` github folder.
4. Update `config/application.yml` accordingly to reflect queues and topics workflow
5. Execute `docker-compose up -d`