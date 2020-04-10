.PHONY: test ctest covdir coverage docs linter qtest clean dep
APP_VERSION:=$(shell cat VERSION | head -1)
GIT_COMMIT:=$(shell git describe --dirty --always)
GIT_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD -- | head -1)
BUILD_USER:=$(shell whoami)
BUILD_DATE:=$(shell date +"%Y-%m-%d")
BINARY:="go-idrac-redfish-api-client"
VERBOSE:=-v
ifdef TEST
	TEST:="-run ${TEST}"
endif

all:
	@echo "Version: $(APP_VERSION), Branch: $(GIT_BRANCH), Revision: $(GIT_COMMIT)"
	@echo "Build on $(BUILD_DATE) by $(BUILD_USER)"
	@mkdir -p bin/
	@CGO_ENABLED=0 go build -o bin/$(BINARY) $(VERBOSE) \
		-ldflags="-w -s \
		-X main.appName=$(BINARY) \
		-X main.appVersion=$(APP_VERSION) \
		-X main.gitBranch=$(GIT_BRANCH) \
		-X main.gitCommit=$(GIT_COMMIT) \
		-X main.buildUser=$(BUILD_USER) \
		-X main.buildDate=$(BUILD_DATE)" \
		-gcflags="all=-trimpath=$(GOPATH)/src" \
		-asmflags="all=-trimpath $(GOPATH)/src" cmd/client/*
	@echo "Done!"

linter:
	@echo "Running lint checks"
	@golint cmd/client/*.go
	@golint pkg/client/*.go
	@golint internal/client/*.go
	@echo "PASS: golint"

test: covdir linter
	@go test $(VERBOSE) -coverprofile=.coverage/coverage.out ./pkg/client/*.go

ctest: covdir linter
	@richgo version || go get -u github.com/kyoh86/richgo
	@time richgo test $(VERBOSE) $(TEST) -coverprofile=.coverage/coverage.out ./pkg/client/*.go

covdir:
	@echo "Creating .coverage/ directory"
	@mkdir -p .coverage

coverage:
	@#go tool cover -help
	@go tool cover -html=.coverage/coverage.out -o .coverage/coverage.html
	@go test -covermode=count -coverprofile=.coverage/coverage.out ./pkg/client/*.go
	@go tool cover -func=.coverage/coverage.out | grep -v "100.0"

docs:
	@mkdir -p .doc
	@go doc -all pkg/client > .doc/index.txt
	@cat .doc/index.txt

clean:
	@rm -rf .doc
	@rm -rf .coverage
	@rm -rf bin/

qtest:
	@echo "Perform quick tests ..."
	@#go test -v -run TestClient ./pkg/client/*.go
	@#go test -v -run TestParseInfoJsonOutput ./pkg/client/*.go
	@#go test -v -run TestParseResourceJsonOutput ./pkg/client/*.go
	@go test -v -run TestParseComputerSystemJsonOutput ./pkg/client/*.go

dep:
	@echo "Making dependencies check ..."
	@go get -u golang.org/x/lint/golint
	@go get -u golang.org/x/tools/cmd/godoc
	@#echo "Clean GOPATH/pkg/dep/sources/ if necessary"
	@#rm -rf $GOPATH/pkg/dep/sources/https---github.com-greenpau*
