# End-to-end Logs injector => VECTOR => LOKI => MINIO


## Setup

### Prerequisites

* docker
* no local running minio, grafana, prometheus, minio (default ports)

### Deployment

```bash
make start
```


## Ensuring it works

```bash
MARKER=TEST1 make inject
MARKER=TEST1 make loki_query
# You should see:   "totalLinesProcessed": 100000,
```

## Clean up

```bash

make purge

```
