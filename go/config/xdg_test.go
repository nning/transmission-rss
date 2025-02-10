package config

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_getXDGDir(t *testing.T) {
	home, _ := os.LookupEnv("HOME")

	dir := getXDGDir("config")
	assert.Equal(t, path.Join(home, ".config", "config.test"), dir)

	dir = GetConfigDir()
	assert.Equal(t, path.Join(home, ".config", "config.test"), dir)

	dir = GetCacheDir()
	assert.Equal(t, path.Join(home, ".cache", "config.test"), dir)

	os.Setenv("XDG_CONFIG_HOME", "/tmp")
	dir = getXDGDir("config")
	assert.Equal(t, "/tmp", dir)
}
