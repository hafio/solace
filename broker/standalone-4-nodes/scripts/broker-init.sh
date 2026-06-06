#!/bin/bash

# 1. Configures "default" vpn message-spool size to 10000MB
# 2. Adds Handy Road CA certificate

CLI_FILENAME="default-vpn-spool.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"

echo "
home
enable
configure
message-spool message-vpn default
max-spool-usage 10000

home
enable
configure
service semp session-idle-timeout 3600
service semp cors allow-any-host
create ssl domain-certificate-authority handy-ca
certificate content \"-----BEGIN CERTIFICATE-----\x0AMIIC0jCCAjSgAwIBAgIUY+P2sCiD8oQ+lqwxobX84TWjPhYwCgYIKoZIzj0EAwQw\x0AXzEbMBkGA1UEAwwSSGFuZHkgQ0EgQXV0aG9yaXR5MQswCQYDVQQGEwJTRzESMBAG\x0AA1UEBwwJU2luZ2Fwb3JlMQ4wDAYDVQQKDAVIQUZJTzEPMA0GA1UECwwGQWRtaW5z\x0AMB4XDTI2MDYwNjIyMjkwNFoXDTM2MDYwMzIyMjkwNFowXzEbMBkGA1UEAwwSSGFu\x0AZHkgQ0EgQXV0aG9yaXR5MQswCQYDVQQGEwJTRzESMBAGA1UEBwwJU2luZ2Fwb3Jl\x0AMQ4wDAYDVQQKDAVIQUZJTzEPMA0GA1UECwwGQWRtaW5zMIGbMBAGByqGSM49AgEG\x0ABSuBBAAjA4GGAAQBgsqlg7o3GdJ0FBDgN33h3SgS3CWACFninu4WOlVLiLyt9wP4\x0A6w5mdE8vI+Zw0tZON9F1eCb2Tn8phb3uIut5DBgAubIhziDTxII0g6I5VNrIJoEH\x0AVncJrUqvg2RSaZF4sklsvTcEbxnUl9jBuDw6hcR106j7H5MqvbmW1oVMwZJjed2j\x0AgYowgYcwHQYDVR0OBBYEFHjv167zRs8zdm3R8lmqUknJVng5MB8GA1UdIwQYMBaA\x0AFHjv167zRs8zdm3R8lmqUknJVng5MCEGA1UdEQQaMBiCD2F1dGhvcml0eS5oYW5k\x0AeYIFaGFuZHkwEgYDVR0TAQH/BAgwBgEB/wIBATAOBgNVHQ8BAf8EBAMCAYYwCgYI\x0AKoZIzj0EAwQDgYsAMIGHAkEsGjRKZXU8Dv2cPOqsSW6670EXWw7T5cV63ZEm4u53\x0AyvI5CbsBgqVO821Kj5FPaaTN0qmChTSUZFk9mGTQhQ7sQwJCARxXoXeopkSiUL9p\x0ALP5oKszHcBTLtZBfK8lLuQs4XAbV9aeC7VDgqiPeX2+VQgHrswL4vKakg3bjTlr4\x0AVHHDm4h1\x0A-----END CERTIFICATE-----\x0A\"

home
enable
configure
create message-vpn vpn-01
authentication basic auth-type internal
no dynamic-message-routing shutdown
no shutdown
exit

message-spool message-vpn vpn-01
max-spool-usage 10000
exit

client-profile default message-vpn vpn-01
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

client-username default message-vpn vpn-01
password default
no shutdown
exit

client-profile default message-vpn default
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

home
enable
configure
create message-vpn ${routername}
authentication basic auth-type internal
no shutdown
exit

message-spool message-vpn ${routername}
max-spool-usage 10000
exit

client-profile default message-vpn ${routername}
message-spool allow-guaranteed-message-send
message-spool allow-guaranteed-message-receive
allow-bridge-connections
replication allow-clients-when-standby
exit

client-username default message-vpn ${routername}
no shutdown
exit" > "${CLI_DIRNAME}/${CLI_FILENAME}"


/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}


