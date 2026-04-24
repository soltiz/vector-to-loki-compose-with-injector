MARKER ?= MYMARKER

start:compose-up bucket-init wait_for_loki health info

info:
	@echo ""
	@echo "Minio - http://localhost:9000"
	@echo "Grafana -  http://localhost:3000"
	@echo "Prometheus - http://localhost:9090"
	@echo "Vector prometheus exporter- http://localhost:9598/metrics"
	@echo ""
	@echo "When you are done : 'make purge'"
	@echo ""
compose-up:
	docker-compose up -d

bucket-init:
	mc alias set docker http://localhost:9000 admin password
	mc mb docker/loki -p

wait_for_loki:
	# Waiting for loki to be starting. It can take up to a few minutes !!!!
	# Note that sometimes, I had to restart loki for it to become actually ready:
	#   ==> docker restart loki-400-loki-1 
	while ! curl -s http://localhost:3100/ready | grep -q "^ready"; do sleep 2; done





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

inject_error:
	echo "mylog _>MARK1<_ kv:init=test,b1=1,b2=2,b3=3,b4=4,b5=5,b6=6,b7=7,b8=8,b9=9,b10=10,b11=11,b12=12,b13=13,b14=14,b15=15,b16=16" | nc localhost 5170 -w1 

