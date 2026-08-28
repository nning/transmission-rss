package aggregator

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"

	"github.com/mmcdole/gofeed"
	"github.com/nning/transmission-rss/go/config"
	"github.com/stretchr/testify/assert"
)

func newTestConfig(t *testing.T, serverURL string) *config.Config {
	t.Helper()

	seenFile := config.NewSeenFile(0, t.TempDir()+"/seen")

	u, err := url.Parse(serverURL)
	if err != nil {
		t.Fatal(err)
	}
	port, _ := strconv.Atoi(u.Port())

	cfg := &config.Config{}
	cfg.Server.Host = u.Hostname()
	cfg.Server.Port = port
	cfg.Server.RpcPath = "/transmission/rpc"
	cfg.SeenFile = seenFile

	return cfg
}

func successRPCHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"result": "success",
		"arguments": map[string]interface{}{
			"torrent-added": map[string]interface{}{"id": 1},
		},
	}
	w.WriteHeader(200)
	_ = json.NewEncoder(w).Encode(response)
}

func Test_match(t *testing.T) {
	assert.True(t, match("Some Show S01E01", "Some Show"))
	assert.True(t, match("foo bar", ".*"))
	assert.True(t, match("foo 1080p", "1080p"))
	assert.True(t, match("foo bar", "(?i)FOO"))
	assert.False(t, match("foo bar", "baz"))
	assert.False(t, match("foo bar", "^bar"))
}

func Test_New(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	assert.NotNil(t, a)
	assert.NotNil(t, a.Client)
	assert.NotNil(t, a.Parser)
	assert.Equal(t, cfg, a.Config)
}

func Test_processItem_alreadySeen(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("unexpected request to server")
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*"}
	item := &gofeed.Item{Title: "Some Show", Link: "http://example.com/torrent"}
	cfg.SeenFile.Add(item.Link)

	a.processItem(feedConfig, item)

	assert.Equal(t, 1, cfg.SeenFile.Count())
}

func Test_processItem_noRegexpMatch(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("unexpected request to server")
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: "xyz"}
	item := &gofeed.Item{Title: "Some Show", Link: "http://example.com/torrent"}

	a.processItem(feedConfig, item)

	assert.True(t, cfg.SeenFile.IsPresent(item.Link))
}

func Test_processItem_addTorrent(t *testing.T) {
	called := false

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: "Some Show"}
	item := &gofeed.Item{Title: "Some Show S01E01", Link: "http://example.com/torrent"}

	a.processItem(feedConfig, item)

	assert.True(t, called)
	assert.True(t, cfg.SeenFile.IsPresent(item.Link))
}

func Test_processItem_addTorrentError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(500)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*"}
	item := &gofeed.Item{Title: "Some Show", Link: "http://example.com/torrent"}

	a.processItem(feedConfig, item)

	// On error, item should not be added to seen
	assert.False(t, cfg.SeenFile.IsPresent(item.Link))
}

func Test_processItem_withEnclosure(t *testing.T) {
	var addedURL string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		addedURL = args["filename"].(string)
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	enclosureURL := "http://example.com/torrent.torrent"
	feedConfig := &config.Feed{RegExp: ".*"}
	item := &gofeed.Item{
		Title:      "Some Show",
		Link:       "http://example.com/item",
		Enclosures: []*gofeed.Enclosure{{URL: enclosureURL}},
	}

	a.processItem(feedConfig, item)

	assert.Equal(t, enclosureURL, addedURL)
	assert.True(t, cfg.SeenFile.IsPresent(enclosureURL))
}

// noEnclosure: link is used both for AddTorrent and as seen key
func Test_processItem_noEnclosure_usesLink(t *testing.T) {
	var addedURL string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		addedURL = args["filename"].(string)
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*"}
	item := &gofeed.Item{Title: "Some Show", Link: "http://example.com/item"}

	a.processItem(feedConfig, item)

	assert.Equal(t, item.Link, addedURL)
	assert.True(t, cfg.SeenFile.IsPresent(item.Link))
}

// seenByGuid, already seen: returns early without calling AddTorrent
func Test_processItem_seenByGuid_alreadySeen(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("unexpected request to server")
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	cfg.SeenFile.Add("some-guid")
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", SeenByGuid: true}
	item := &gofeed.Item{
		Title: "Some Show",
		Link:  "http://example.com/torrent",
		GUID:  "some-guid",
	}

	a.processItem(feedConfig, item)

	assert.Equal(t, 1, cfg.SeenFile.Count())
}

// seenByGuid, first time: GUID goes into seen, not the URL
func Test_processItem_seenByGuid_tracksGuid(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", SeenByGuid: true}
	item := &gofeed.Item{
		Title: "Some Show",
		Link:  "http://example.com/torrent",
		GUID:  "guid-123",
	}

	a.processItem(feedConfig, item)

	assert.True(t, cfg.SeenFile.IsPresent("guid-123"))
	assert.False(t, cfg.SeenFile.IsPresent(item.Link))
}

// seenByGuid + enclosure: AddTorrent gets enclosure URL, but GUID is the seen key
func Test_processItem_seenByGuid_withEnclosure_tracksGuid(t *testing.T) {
	var addedURL string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		addedURL = args["filename"].(string)
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	enclosureURL := "http://example.com/file.torrent"
	feedConfig := &config.Feed{RegExp: ".*", SeenByGuid: true}
	item := &gofeed.Item{
		Title:      "Some Show",
		Link:       "http://example.com/item",
		GUID:       "guid-abc",
		Enclosures: []*gofeed.Enclosure{{URL: enclosureURL}},
	}

	a.processItem(feedConfig, item)

	assert.Equal(t, enclosureURL, addedURL)
	assert.True(t, cfg.SeenFile.IsPresent("guid-abc"))
	assert.False(t, cfg.SeenFile.IsPresent(enclosureURL))
}

// seenByGuid + no enclosure: Link sent to AddTorrent, GUID in seen
func Test_processItem_seenByGuid_noEnclosure_tracksGuid(t *testing.T) {
	var addedURL string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		addedURL = args["filename"].(string)
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", SeenByGuid: true}
	item := &gofeed.Item{
		Title: "Some Show",
		Link:  "http://example.com/item",
		GUID:  "guid-xyz",
	}

	a.processItem(feedConfig, item)

	assert.Equal(t, item.Link, addedURL)
	assert.True(t, cfg.SeenFile.IsPresent("guid-xyz"))
	assert.False(t, cfg.SeenFile.IsPresent(item.Link))
}

// seenByGuid + no regexp match: GUID (not URL) added to seen
func Test_processItem_seenByGuid_noRegexpMatch(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Error("unexpected request to server")
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: "WILL_NOT_MATCH", SeenByGuid: true}
	item := &gofeed.Item{
		Title: "Some Show",
		Link:  "http://example.com/torrent",
		GUID:  "guid-nomatch",
	}

	a.processItem(feedConfig, item)

	assert.True(t, cfg.SeenFile.IsPresent("guid-nomatch"))
	assert.False(t, cfg.SeenFile.IsPresent(item.Link))
}

func Test_processItem_withSeedRatio(t *testing.T) {
	postCount := 0

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		postCount++
		successRPCHandler(w, r)
	}))
	defer server.Close()

	cfg := newTestConfig(t, server.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", SeedRatioLimit: 0.5}
	item := &gofeed.Item{Title: "Some Show", Link: "http://example.com/torrent"}

	a.processItem(feedConfig, item)

	// AddTorrent + SetTorrent = 2 RPC calls
	assert.Equal(t, 2, postCount)
}

func Test_processFeed(t *testing.T) {
	rssContent := `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Show S01E01</title>
      <link>http://example.com/torrent1</link>
    </item>
  </channel>
</rss>`

	rpcCalled := false
	rpcServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rpcCalled = true
		successRPCHandler(w, r)
	}))
	defer rpcServer.Close()

	feedServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprint(w, rssContent)
	}))
	defer feedServer.Close()

	cfg := newTestConfig(t, rpcServer.URL)
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", Url: feedServer.URL}
	a.processFeed(feedConfig)

	assert.True(t, rpcCalled)
}

func Test_processFeed_error(t *testing.T) {
	cfg := newTestConfig(t, "http://localhost:1")
	a := New(cfg)

	feedConfig := &config.Feed{RegExp: ".*", Url: "http://localhost:1/nonexistent"}

	// Should log error and not panic
	a.processFeed(feedConfig)
}

func Test_Run(t *testing.T) {
	rssContent := `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Show S01E01</title>
      <link>http://example.com/torrent1</link>
    </item>
  </channel>
</rss>`

	addCount := 0
	rpcServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		addCount++
		successRPCHandler(w, r)
	}))
	defer rpcServer.Close()

	feedServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = fmt.Fprint(w, rssContent)
	}))
	defer feedServer.Close()

	cfg := newTestConfig(t, rpcServer.URL)
	cfg.Feeds = []config.Feed{
		{RegExp: ".*", Url: feedServer.URL},
		{RegExp: ".*", Url: feedServer.URL},
	}
	a := New(cfg)

	a.Run()

	// Second feed finds the item already seen
	assert.Equal(t, 1, addCount)
}
