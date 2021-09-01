MAKEFILE_PATH = $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR = $(dir $(MAKEFILE_PATH))
BIN_DIR = $(CURRENT_DIR)/bin

.PHONY: build clean deploy

build:
	cd $(CURRENT_DIR)/services/dynamodb-writer; env GOARCH=amd64 GOOS=linux go build -ldflags="-s -w" -o $(BIN_DIR)/dynamodb-writer main.go
	cd $(CURRENT_DIR)/services/dynamodb-reader; env GOARCH=amd64 GOOS=linux go build -ldflags="-s -w" -o $(BIN_DIR)/dynamodb-reader main.go

clean:
	rm -rf ./bin

deploy: clean build
	sls deploy --verbose --stage dev

infra:
	cd $(CURRENT_DIR)/infrastructure/terraform; terraform apply
