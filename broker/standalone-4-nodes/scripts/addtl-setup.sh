#!/bin/bash

# 1. Configures "default" vpn message-spool size to 10000MB
# 2. Adds Handy Road CA certificate

CLI_FILENAME="addtl-setup.cli"
CLI_DIRNAME="/usr/sw/jail/cliscripts"

echo "
home
enable
configure
create message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  authentication
    basic auth-type none
    no basic radius-domain
    no basic shutdown
    exit
  semp-over-msgbus shutdown
  semp-over-msgbus show-cmds shutdown
  semp-over-msgbus admin-cmds shutdown
  semp-over-msgbus admin-cmds distributed-cache-cmds shutdown
  semp-over-msgbus admin-cmds client-cmds shutdown
  service smf max-connections 1000
  no service smf plain-text shutdown
  no service smf ssl shutdown
  no service web-transport plain-text shutdown
  no service web-transport ssl shutdown
  exit

! Create Client Profile: \"default\"
client-profile \"default\" message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  allow-bridge-connections
  no message-spool allow-guaranteed-endpoint-create
  message-spool allow-guaranteed-message-receive
  message-spool allow-guaranteed-message-send
  no message-spool allow-transacted-sessions
  no replication allow-clients-when-standby
  no ssl allow-downgrade-to-plain-text
  no compression shutdown
  exit

! Create Message Spool: \"A VPN WITH LONG NAME AND SPACES\"
message-spool message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  max-spool-usage 1000
  exit

! Create Endpoints: \"A VPN WITH LONG NAME AND SPACES\"
message-spool message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  create queue \"A QUEUE WITH LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME\" is-well-known
    access-type \"non-exclusive\"
    max-bind-count 1000
    max-delivered-unacked-msgs-per-flow 10000
    max-message-size 10000000
    max-spool-usage 5000
    no owner
    permission all consume
    subscription topic \"test/>\"
    subscription topic \"test1\"
    no shutdown ingress
    no shutdown egress
    exit
  create queue \"ANOTHER QUEUE WITH LONG NAME AND SPACE AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES AND LONG NAME AND SPACES\" is-well-known
    access-type \"non-exclusive\"
    max-bind-count 1000
    max-delivered-unacked-msgs-per-flow 10000
    max-message-size 10000000
    max-spool-usage 5000
    no owner
    permission all consume
    subscription topic \"test/>\"
    subscription topic \"test2\"
    no shutdown ingress
    no shutdown egress
    exit
  exit

! Create ACL Profile: \"default\"
acl-profile \"default\" message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  client-connect default-action allow
  publish-topic default-action allow
  subscribe-topic default-action allow
  subscribe-share-name default-action allow
  exit

! Create Client Username: \"default\"
client-username default message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  acl-profile default
  client-profile default
  no guaranteed-endpoint-permission-override
  aes-password \"9i3TGQFvGV5shkNCkmH73qVoBbn4EWNMLnpg8u9Qr+pJ2i+ShdUjKR5XBBFHRTJivPpCLzMmSvu6eJBdp7tN2eEm8jVoAVSBhDbXPWmfpWelmjDSFqhAX5fdSspdRrqloSfBjyLQJUl2bt6ZIvb92dN1AmCJ9NU3BtDKb8PiFgc=\"
  no subscription-manager
  no shutdown
  exit

! Enable Message Vpn: \"A VPN WITH LONG NAME AND SPACES\"
message-vpn \"A VPN WITH LONG NAME AND SPACES\"
  no shutdown
  replication
    state \"standby\"
    shutdown
    exit
  exit

create message-vpn \"VPN WITH MANY QUEUES\"
message-vpn \"VPN WITH MANY QUEUES\"
  no alias
  authentication
    basic auth-type none
    no basic shutdown
    exit
  semp-over-msgbus shutdown
  semp-over-msgbus show-cmds shutdown
  semp-over-msgbus admin-cmds shutdown
  semp-over-msgbus admin-cmds distributed-cache-cmds shutdown
  semp-over-msgbus admin-cmds client-cmds shutdown
  service smf max-connections 1000
  no service smf plain-text shutdown
  no service smf ssl shutdown
  no service web-transport plain-text shutdown
  no service web-transport ssl shutdown
  no ssl allow-downgrade-to-plain-text
  exit

client-profile default message-vpn \"VPN WITH MANY QUEUES\"
  allow-bridge-connections
  no message-spool allow-guaranteed-endpoint-create
  message-spool allow-guaranteed-message-receive
  message-spool allow-guaranteed-message-send
  no message-spool allow-transacted-sessions
  no replication allow-clients-when-standby
  no ssl allow-downgrade-to-plain-text
  no compression shutdown
  exit

! Create Message Spool: \"VPN WITH MANY QUEUES\"
message-spool message-vpn \"VPN WITH MANY QUEUES\"
  max-spool-usage 1000
  max-transacted-sessions 1000
  max-transactions 5000
  max-endpoints 1000
  max-egress-flows 1000
  max-ingress-flows 1000
  exit

! Create ACL Profile: default
acl-profile default message-vpn \"VPN WITH MANY QUEUES\"
  client-connect default-action allow
  publish-topic default-action allow
  subscribe-topic default-action allow
  subscribe-share-name default-action allow
  exit

! Create Client Username: default
client-username default message-vpn \"VPN WITH MANY QUEUES\"
  acl-profile default
  client-profile default
  no guaranteed-endpoint-permission-override
  aes-password \"ksZ37RJJZqiwWftkJqgdUUTkBE6zMP+arO0EyCnpg+tsORn6nDl73fZbvVIgsNC5\"
  no subscription-manager
  no shutdown
  exit

message-vpn \"VPN WITH MANY QUEUES\"
  no shutdown
  replication
    state \"standby\"
    shutdown
    exit
  exit

home
enable
configure
message-spool message-vpn \"VPN WITH MANY QUEUES\"


" > "${CLI_DIRNAME}/${CLI_FILENAME}"

for i in $(seq -f "%03g" 0 900); do
    echo "
  create queue QUEUE-${i}
    access-type non-exclusive
    no owner
    permission all consume
    subscription topic test/all
    subscription topic test/${i}
    no shutdown full
    exit
  " >> "${CLI_DIRNAME}/${CLI_FILENAME}"
done

/usr/sw/loads/currentload/bin/cli -Apes ${CLI_FILENAME}
