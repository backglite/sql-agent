IMAGE_NAME := dbhi/sql-agent
PROG_NAME := sql-agent

GIT_SHA := $(or $(shell git log -1 --pretty=format:"%h" .), "latest")
GIT_TAG := $(shell git describe --tags --exact-match . 2>/dev/null)
GIT_BRANCH := $(shell git symbolic-ref -q --short HEAD)

build:
	go build \
		-o $(GOPATH)/bin/sql-agent \
		./cmd/sql-agent

dist-build:
	mkdir -p dist
	cp -f $(GOPATH)/bin/sql-agent ./dist/

dist:
	docker build -f Dockerfile.build -t dbhi/sql-agent-builder .
	docker run --rm -it \
		-v ${PWD}:/go/src/github.com/chop-dbhi/sql-agent \
		dbhi/sql-agent-builder

docker:
	docker build -t ${IMAGE_NAME}:${GIT_SHA} .
	docker tag ${IMAGE_NAME}:${GIT_SHA} ${IMAGE_NAME}:${GIT_BRANCH}
	if [ -n "${GIT_TAG}" ] ; then \
		docker tag ${IMAGE_NAME}:${GIT_SHA} ${IMAGE_NAME}:${GIT_TAG} ; \
  fi;
	if [ "${GIT_BRANCH}" == "master" ]; then \
		docker tag ${IMAGE_NAME}:${GIT_SHA} ${IMAGE_NAME}:latest ; \
	fi;

prepareDeps:
	go get -d

deps:
	go get github.com/chop-dbhi/sql-agent
	go get github.com/denisenkom/go-mssqldb
	go get github.com/go-sql-driver/mysql
	go get github.com/lib/pq
	go get github.com/mattn/go-oci8
	go get github.com/mattn/go-sqlite3
	go get github.com/snowflakedb/gosnowflake

prepare: deps prepareDeps

all: prepare build dist-build dist

.PHONY: prepare prepareDeps build dist-build dist
