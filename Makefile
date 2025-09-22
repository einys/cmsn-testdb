.PHONY: up replset status dump-twitter restore-twitter dump-bsky restore-bsky drop-restore-twitter drop-restore-bsky

# ===== 기본 설정 =====
CONTAINER_NAME=test-mongo
MONGO_IMAGE=mongo:6
HOST_PORT=27017
DB_PATH=/Users/ysunny/Workspace/cmsn-testdb

# ===== 1. 임시 DB 띄우기 =====
up:
	docker run --rm -d -p $(HOST_PORT):27017 --name $(CONTAINER_NAME) $(MONGO_IMAGE) --replSet rs0 --bind_ip_all

# ===== 2. 레플리카셋 초기화 =====
replset:
	@echo "⏳ Waiting for MongoDB to be ready..."
	@until docker exec $(CONTAINER_NAME) mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; do \
		echo "   MongoDB not ready yet, retrying..."; \
		sleep 2; \
	done
	@echo "✅ MongoDB is ready, initiating replica set..."
	docker exec $(CONTAINER_NAME) mongosh --eval 'rs.initiate({ _id: "rs0", members: [{ _id: 0, host: "127.0.0.1:27017" }] })'


# ===== 3. 레플리카셋 상태 확인 =====
status:
	docker exec -it $(CONTAINER_NAME) mongosh --eval 'printjson(rs.status().members)'

# ===== 4. 트위터 DB dump (실제 DB → 로컬) =====
dump-twitter:
	export $$(grep DATABASE_URI .env) && \
	mongodump --uri="$$DATABASE_URI" --db=twitter --out=$(DB_PATH)/twitter-db-dump

# ===== 5. 트위터 DB restore (로컬 dump → docker) =====
restore-twitter:
	docker cp $(DB_PATH)/twitter-db-dump/twitter $(CONTAINER_NAME):/dump/twitter
	docker exec -it $(CONTAINER_NAME) mongorestore --db=twitter /dump/twitter

drop-restore-twitter:
	docker cp $(DB_PATH)/twitter-db-dump/twitter $(CONTAINER_NAME):/dump
	docker exec -it $(CONTAINER_NAME) mongorestore --drop --db=twitter /dump/twitter

# ===== 6. 블루스카이 DB dump (실제 DB → 로컬) =====
dump-bsky:
	@export $$(grep DATABASE_URI .env) && \
	mongodump --uri="$$DATABASE_URI" --db=bsky --out=$(DB_PATH)/bsky-db-dump

# ===== 7. 블루스카이 DB restore (로컬 dump → docker) =====
restore-bsky:
	docker cp $(DB_PATH)/bsky-db-dump/bsky $(CONTAINER_NAME):/dump/bsky
	docker exec -it $(CONTAINER_NAME) mongorestore --db=bsky /dump/bsky

drop-restore-bsky:
	docker cp $(DB_PATH)/bsky-db-dump/bsky $(CONTAINER_NAME):/dump
	docker exec -it $(CONTAINER_NAME) mongorestore --drop --db=bsky /dump/bsky

# ===== 8. 전체 동작 =====
dump-all: dump-twitter dump-bsky
restore-all: restore-twitter restore-bsky
drop-restore-all: drop-restore-twitter drop-restore-bsky

# ===== 9. 전체 플로우 (DB 띄우기 → replset → dump → restore) =====
all: up replset status dump-all restore-all