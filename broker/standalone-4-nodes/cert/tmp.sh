#!/bin/bash

openssl genrsa -out root.key 4096

openssl req -new -x509 -days 1000 -key root.key -out server.pem -subj "/C=/ST=/L=/O=/OU=/CN=solxps.handy"

cat root.key > server_cert.pem
cat server.pem >> server_cert.pem
