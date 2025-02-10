package config

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
)

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
	file, _ := os.Create(c)
	defer file.Close()

	assert.Equal(t, c, getPath(root))

	err = os.RemoveAll(root)
	assert.Nil(t, err)
}
