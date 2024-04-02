.PHONY: clean test lint

DESTDIR = ~/.local
PREFIX = $(DESTDIR)/bin

SOURCES = $(shell find . -name \*.go)

BIN_DIR = cmd/transmission-rss
BIN_FILE = transmission-rss
BIN = $(BIN_DIR)/$(BIN_FILE)

GOLDFLAGS += -X main.Version=$(VERSION)
GOLDFLAGS += -X main.Buildtime=$(BUILDTIME)
GOFLAGS += -ldflags "$(GOLDFLAGS)"
CGO_ENABLED = 1

build: $(BIN)
all: build

$(BIN): $(SOURCES)
	cd $(BIN_DIR); CGO_ENABLED=$(CGO_ENABLED) go build $(GOFLAGS)

clean:
	rm -f $(BIN)

run: $(BIN)
	./$(BIN) $(args)

test:
	go test -cover -coverprofile .coverage ./...

coverage: test
	go tool cover -html .coverage

lint:
	golint ./...

build_pie: GOLDFLAGS += -s -w -linkmode external -extldflags \"$(LDFLAGS)\"
build_pie: GOFLAGS += -trimpath -buildmode=pie -mod=readonly -modcacherw
build_pie: build

release: build_pie
	upx -qq --best $(BIN)
	ls -lh $(BIN)

install: build_pie completion man
	mkdir -p $(PREFIX)
	cp $(BIN) $(PREFIX)
