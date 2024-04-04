.PHONY: clean test lint

DESTDIR = ~/.local
PREFIX = $(DESTDIR)/bin

SOURCES = $(shell find . -name \*.go)

BIN_DIR = cmd/transmission-rss
BIN_FILE = transmission-rss
BIN = $(BIN_DIR)/$(BIN_FILE)

GOLDFLAGS =
GOFLAGS += -ldflags "$(GOLDFLAGS)"
CGO_ENABLED = 0

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

build_release: GOLDFLAGS += -s -w
build_release: GOFLAGS += -trimpath -mod=readonly -modcacherw
build_release: build

upx:
	upx -qq --best $(BIN)

release: build_release upx

install: release
	mkdir -p $(PREFIX)
	cp $(BIN) $(PREFIX)
