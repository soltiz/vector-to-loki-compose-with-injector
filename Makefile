MARKER ?= MYMARKER

all: start health

start:
	docker-compose up -d
	mc alias set docker http://localhost:9000 admin password
	mc mb docker/loki -p
	@echo "Minio - http://localhost:9000"
	@echo "Grafana -  http://localhost:3000"
	@echo "Prometheus - http://localhost:9090"
	@echo "Vector prometheus exporter- http://localhost:9598/metrics"

	# Waiting for loki to be starting
	while ! curl -s http://localhost.3100 | grep -q "^ready"; do sleep 2; done




health: loki_health minio_health

inject:
	python injector.py -n 100000  -r 5000 -p 5170 -m $(MARKER)

inject_load:
	python injector.py -n 1000000  -r 50000 -p 5170 -m $(MARKER)


vector_metrics:
	curl -s localhost:9598/metrics | grep loki | grep events_total | sed 's/{.*}//g' | sed 's/ [0-9]*$$//g'

vector_logs: 
	docker logs loki-400-vector-1 -f

loki_health:
	#
	# Checking Loki health:
	#
	curl -s http://localhost:3100/ready
	@curl -s http://localhost:3100/ready | grep -q '^ready'

loki_query:
	# Query for some logs
	curl -G -s "http://localhost:3100/loki/api/v1/query_range"   --data-urlencode 'query={marker="$(MARKER)"}'   --data-urlencode 'since=10m'  --data-urlencode 'limit=5'  | jq '.data.result[].values[]'
	# Query for stats
	curl -sG "http://localhost:3100/loki/api/v1/query_range"  --data-urlencode 'query=count_over_time({marker="$(MARKER)"}[1m])'  | jq '.data.stats.summary'


loki_logs:
		docker logs loki-400-loki-1 -f


minio_health:
	#
	# Checking Minio health:
	#
	mc admin info docker --json | jq 'del(.info)'

minio_info:
	mc admin info docker

purge:
	docker-compose down -v