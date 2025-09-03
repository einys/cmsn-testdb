### 임시 DB 띄우기
1. mongodb를 docker container로 실행
```
docker run --rm -d -p 27017:27017 --name test-mongo mongo:6 --replSet rs0 --bind_ip_all
```
2. replicaset init 실행(왜냐면 transaction 묶음 실행 시 꼭 레플리카셋이어야 함)
``` 
docker exec -it test-mongo mongosh --eval '
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "127.0.0.1:27017" }
    ]
  })
'
```
실행 결과: { ok: 1 }

3. 몇 초 기다린 후 잘 초기화됐는지 확인
```
docker exec -it test-mongo mongosh --eval 'printjson(rs.status().members)'
```

실행 정상 결과:
```
[
  {
    _id: 0,
    name: '127.0.0.1:27017',
    health: 1,
    state: 1,
    stateStr: 'PRIMARY',
    uptime: 50,
    optime: {
      ts: Timestamp({ t: 1753301062, i: 17 }),
      t: Long('1')
    },
    optimeDate: ISODate('2025-07-23T20:04:22.000Z'),
    lastAppliedWallTime: ISODate('2025-07-23T20:04:22.353Z'),
    lastDurableWallTime: ISODate('2025-07-23T20:04:22.353Z'),
    syncSourceHost: '',
    syncSourceId: -1,
    infoMessage: 'Could not find member to sync from',
    electionTime: Timestamp({ t: 1753301062, i: 2 }),
    electionDate: ISODate('2025-07-23T20:04:22.000Z'),
    configVersion: 1,
    configTerm: 1,
    self: true,
    lastHeartbeatMessage: ''
  }
]
```

### env
vscode의 버튼으로 실행 시에는 env 세팅이 되어 있음 (/.vscode/settings.json)
아니고 터미널에서 직접 실행하는 경우
```
export DATABASE_URI=mongodb://localhost:27017
```


### 실제 db에서 twitter 토큰 데이터 복사 (.env에 mongodb 연결 DATABASE_URI 가 있어야 함)
export $(grep DATABASE_URI .env) &&
mongodump --uri="$DATABASE_URI" --db=twitter --out=/Users/ysunny/Workspace/cmsn-testdb/twitter-db-dump
- 위치는 /Users/ysunny/Workspace/cmsn-testdb/twitter-db-dump

### 테스트용 docker: test-mongo에, twitter collection에 위에서 가져온 로컬 파일을 복사
docker cp /Users/ysunny/Workspace/cmsn-testdb/twitter-db-dump/twitter test-mongo:/dump
docker exec -it test-mongo mongorestore --db=twitter /dump/twitter

- 기존에 twitter DB가 이미 존재하는데 다시 덤프 내용으로 덮어쓰고 싶다면 db 드랍 후 재생성:
docker exec -it test-mongo mongorestore --drop --db=twitter /dump/twitter

### bsky 동일하게 클라우드의 내 db(.env에 명시)에서 데이터 가져옴
export $(grep DATABASE_URI .env) &&
mongodump --uri="$DATABASE_URI" --db=bsky --out=/Users/ysunny/Workspace/cmsn-testdb/bsky-db-dump

### 가져온 데이터가 있는 로컬 파일을 로컬 테스트용 docker에 넣기
docker cp /Users/ysunny/Workspace/cmsn-testdb/bsky-db-dump/bsky test-mongo:/dump
docker exec -it test-mongo mongorestore --db=bsky /dump/bsky