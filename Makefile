.PHONY: clean test lint

DESTDIR = ~/.local
PREFIX = $(DESTDIR)/bin

SOURCES = $(shell find . -name \*.go)

MAIN_BIN_DIR = cmd/transmission-rss
MAIN_BIN_FILE = transmission-rss
MAIN_BIN = $(MAIN_BIN_DIR)/$(MAIN_BIN_FILE)

ADD_BIN_DIR = cmd/transmission-add
ADD_BIN_FILE = transmission-add
ADD_BIN = $(ADD_BIN_DIR)/$(ADD_BIN_FILE)

GOOS =
GOARCH =
GOLDFLAGS =
GOFLAGS += -ldflags "$(GOLDFLAGS)"
CGO_ENABLED = 0

build: $(MAIN_BIN) $(ADD_BIN)
all: build

$(MAIN_BIN): $(SOURCES)
	cd $(MAIN_BIN_DIR); CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) go build $(GOFLAGS)

$(ADD_BIN): $(SOURCES)
	cd $(ADD_BIN_DIR); CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) go build $(GOFLAGS)

clean:
	rm -f $(MAIN_BIN) $(ADD_BIN)

run: $(MAIN_BIN)
	./$(MAIN_BIN) $(args)

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
	upx -qq --best $(MAIN_BIN) $(ADD_BIN)

release: build_release upx

install: release
	mkdir -p $(PREFIX)
	cp $(MAIN_BIN) $(PREFIX)
	cp $(ADD_BIN) $(PREFIX)
