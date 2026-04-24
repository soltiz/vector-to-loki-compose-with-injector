# End-to-end Logs injector => VECTOR => LOKI => MINIO


## Disclaimer

THIS IS AN UNSAFE SETUP FOR TEST PURPOSE !!! NOT FOR PRODUCTION (there are hard-coded default unsafe credentials)

## What it does

This starts in local docker a bunch of usual logs processing and monitoring tools
- A LOKI for logs storage
- A Minio, used as LOKI storage backend
- a Vector pipeline, to receive logs on a TCP port (5170) and send them to LOKI (a local on-disk buffer is configured if loki is too slow or unavailable)
- a Prometheus for storing vector metrics
- a Grafana for exploring LOKI-stored logs, and Prometheus-stored metrics
- a custom Python injector allowing fixed-rates injection of numbered text logs (not using a standard format)

Injector inserts a custom MARKER inside the logs, that you can choose upon injection.
This allows you to filter logs in loki, using the 'marker' label

## Setup

### Prerequisites

* docker
* no local running minio, grafana, prometheus, minio (default ports)

### Deployment

```bash
make start

# Note that sometimes, I had to restart loki for it to become actually ready:
docker restart loki-400-loki-1 

```


## Ensuring it works

```bash
MARKER=TEST1 make inject

make vector_metrics
# You should see 'vector_component_received_events_total 100000' if you did not inject anything else


MARKER=TEST1 make loki_query
# You should see:   "totalLinesProcessed": 100000,
```

## Clean up

```bash

make purge

```
