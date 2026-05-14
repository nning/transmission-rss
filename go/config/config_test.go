package config

import (
	"fmt"
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func Test_Config_New(t *testing.T) {
	dir := t.TempDir()
	configPath := path.Join(dir, "config.yml")

	yaml := `
feeds:
  - url: http://example.com/feed
    regexp: ".*"
server:
  host: myhost
  port: 9999
update_interval: 300
`
	err := os.WriteFile(configPath, []byte(yaml), 0600)
	assert.Nil(t, err)

	cfg := New(configPath)

	assert.NotNil(t, cfg)
	assert.Len(t, cfg.Feeds, 1)
	assert.Equal(t, "http://example.com/feed", cfg.Feeds[0].Url)
	assert.Equal(t, "myhost", cfg.Server.Host)
	assert.Equal(t, 9999, cfg.Server.Port)
	assert.Equal(t, 300, cfg.UpdateInterval)
	assert.Equal(t, configPath, cfg.ConfigPath)
	assert.NotNil(t, cfg.SeenFile)
}

func Test_Config_New_defaults(t *testing.T) {
	dir := t.TempDir()
	configPath := path.Join(dir, "config.yml")
	err := os.WriteFile(configPath, []byte("feeds: []\n"), 0600)
	assert.Nil(t, err)

	cfg := New(configPath)

	assert.Equal(t, "localhost", cfg.Server.Host)
	assert.Equal(t, 9091, cfg.Server.Port)
	assert.Equal(t, "/transmission/rpc", cfg.Server.RpcPath)
	assert.Equal(t, 600, cfg.UpdateInterval)
}

func Test_Config_ServerURL(t *testing.T) {
	cfg := &Config{}
	cfg.Server.Host = "localhost"
	cfg.Server.Port = 9091
	cfg.Server.RpcPath = "/transmission/rpc"

	assert.Equal(t, "http://localhost:9091/transmission/rpc", cfg.ServerURL())

	cfg.Server.Tls = true
	assert.Equal(t, "https://localhost:9091/transmission/rpc", cfg.ServerURL())
}

func Test_Config_ServerURL_customHost(t *testing.T) {
	cfg := &Config{}
	cfg.Server.Host = "transmission.example.com"
	cfg.Server.Port = 8080
	cfg.Server.RpcPath = "/rpc"

	assert.Equal(t, fmt.Sprintf("http://%s:%d%s", "transmission.example.com", 8080, "/rpc"), cfg.ServerURL())
}

func Test_defaultString(t *testing.T) {
	assert.Equal(t, "default", defaultString("", "default"))
	assert.Equal(t, "value", defaultString("value", "default"))
}

func Test_defaultInt(t *testing.T) {
	assert.Equal(t, 1, defaultInt(0, 1))
	assert.Equal(t, 1, defaultInt(1, 2))
}

func Test_getPath(t *testing.T) {
	root := "/tmp/transmission-rss-test"

	assert.Equal(t, "", getPath(root))

	err := os.MkdirAll(root, 0700)
	assert.Nil(t, err)

	p := path.Join(root, os.Getenv("HOME"), ".config", "config.test")
	err = os.MkdirAll(p, 0700)
	assert.Nil(t, err)

	c := path.Join(p, "config.yml")
	file, err := os.Create(c)
	require.NoError(t, err)
	defer func() { _ = file.Close() }()

	assert.Equal(t, c, getPath(root))

	err = os.RemoveAll(root)
	assert.Nil(t, err)
}
