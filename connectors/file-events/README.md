# Solace File-Event Connector

This project contains the files to quickly spin up a Solace-File Event Connector v3.0.0 (internally available at time of this publication).

# Configuration and Behaviour

The connector is configured:
1. to read a pipe ("|") delimited file line by line
2. sends each line as a solace message
3. delimited content is converted into a flat json message
4. Run continuously and scans the directory every 10s

## Other parameters:
| Parameter | Value |
| - | - |
| Source Directory CFG | `/app/external/spring/config/dir.cfg` |
| Destination Topic | `fe/source/test` (static) |
| LVQ Name | `femi.lvq` |
| LVQ Topic | `solace/connector/file/events/source/test` |
| Connector Start Event Message | `false` |
| Connector Complete Event Message | `false` |
| File Start Event Message | `false` |
| File Complete Event Message | `false` |
| Column Delimited | "\|" |
| Ignore First Event of Delimited File | `false` |
| Use First Event as Header | `true` |
| Trim Columns | `true` |
| Output | JSON |
| Pretty Print Json | `true` |
