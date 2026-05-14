package client

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"

	"github.com/nning/transmission-rss/go/config"
	"github.com/stretchr/testify/assert"
)

func newTestConfig(serverURL string) *config.Config {
	u, _ := url.Parse(serverURL)
	port, _ := strconv.Atoi(u.Port())

	cfg := &config.Config{}
	cfg.Server.Host = u.Hostname()
	cfg.Server.Port = port
	cfg.Server.RpcPath = "/transmission/rpc"

	return cfg
}

func successResponse(id int) map[string]interface{} {
	return map[string]interface{}{
		"result": "success",
		"arguments": map[string]interface{}{
			"torrent-added": map[string]interface{}{"id": id},
		},
	}
}

func Test_Client_New(t *testing.T) {
	cfg := &config.Config{}
	c := New(cfg)

	assert.NotNil(t, c)
	assert.Equal(t, cfg, c.Config)
}

func Test_Client_AddTorrent_success(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(successResponse(42))
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	id, err := c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.Nil(t, err)
	assert.Equal(t, 42, id)
}

func Test_Client_AddTorrent_duplicate(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"result": "success",
			"arguments": map[string]interface{}{
				"torrent-duplicate": map[string]interface{}{"id": 7},
			},
		})
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	id, err := c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.Nil(t, err)
	assert.Equal(t, 7, id)
}

func Test_Client_AddTorrent_rpcError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(500)
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	id, err := c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.NotNil(t, err)
	assert.Equal(t, 0, id)
}

func Test_Client_AddTorrent_resultError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"result": "some rpc error"})
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	id, err := c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.NotNil(t, err)
	assert.Equal(t, 0, id)
}

func Test_Client_AddTorrent_withDownloadDir(t *testing.T) {
	var receivedDir string

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		receivedDir = args["download-dir"].(string)
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(successResponse(1))
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))
	_, _ = c.AddTorrent("magnet:?xt=urn:btih:abc", "/downloads/shows")

	assert.Equal(t, "/downloads/shows", receivedDir)
}

func Test_Client_AddTorrent_paused(t *testing.T) {
	var receivedPaused bool

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var body map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&body)
		args := body["arguments"].(map[string]interface{})
		receivedPaused = args["paused"].(bool)
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(successResponse(1))
	}))
	defer server.Close()

	cfg := newTestConfig(server.URL)
	cfg.Paused = true
	c := New(cfg)

	_, _ = c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.True(t, receivedPaused)
}

func Test_Client_SetTorrent(t *testing.T) {
	called := false

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		called = true
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"result": "success"})
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	c.SetTorrent(RequestArguments{
		"ids":            []int{1},
		"seedRatioLimit": 0.5,
		"seedRatioMode":  1,
	})

	assert.True(t, called)
}

func Test_Client_rpc_retry409(t *testing.T) {
	postCount := 0

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			// getSessionId expects 409 with the session ID header
			w.Header().Set("X-Transmission-Session-Id", "new-session-id")
			w.WriteHeader(409)
			return
		}

		postCount++
		if postCount == 1 {
			// First POST triggers session renewal
			w.WriteHeader(409)
			return
		}

		// Second POST succeeds
		w.WriteHeader(200)
		_ = json.NewEncoder(w).Encode(successResponse(1))
	}))
	defer server.Close()

	c := New(newTestConfig(server.URL))

	id, err := c.AddTorrent("magnet:?xt=urn:btih:abc", "")

	assert.Nil(t, err)
	assert.Equal(t, 1, id)
	assert.Equal(t, 2, postCount)
}
