## Setup

Lancer Loki:



```bash

docker run -d \
  --name loki \
  -p 3100:3100 \
  -v $(pwd)/loki-config.yaml:/etc/loki/config.yaml \
  grafana/loki:latest \
  -config.file=/etc/loki/config.yaml



docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  -e "MINIO_ROOT_USER=admin" \
  -e "MINIO_ROOT_PASSWORD=password" \
  --name minio \
  quay.io/minio/minio server /data --console-address ":9001"
  
```




## injection

```python

#!/usr/bin/python

import socket
import time



HOST = "127.0.0.1"
PORT = 5170
RATE = 10000       # logs/sec
DURATION = 60      # seconds
BATCH_SIZE = 500   # logs per send
MARKER = "BOB"


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect((HOST, PORT))

start = time.time()
counter = 0

while time.time() - start < DURATION:
    batch = []
    for _ in range(BATCH_SIZE):
        counter += 1
        batch.append(f"log_{MARKER}_{counter} {time.time()}\n")
    
    sock.sendall("".join(batch).encode())

    # contrôle du débit
    time.sleep(BATCH_SIZE / RATE)

end = time.time()
delta = end - start
sock.close()
print(f"Send {counter} messages in {delta}.")
```

```bash
curl -G -s "http://localhost:3100/loki/api/v1/query_range"   --data-urlencode 'query={source="vector"}'   --data-urlencode 'since=10m'  --data-urlencode 'limit=5000'  | jq '.data.result[].values[][1]' -r | jq .message -r
```

## Query



```bash
curl -G -s "http://localhost:3100/loki/api/v1/query_range"   --data-urlencode 'query={source="vector"}'   --data-urlencode 'since=10m'  --data-urlencode 'limit=5000'  | jq '.data.result[].values[][1]' -r | jq .message -r
```