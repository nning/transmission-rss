package config

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_NewSeenFile(t *testing.T) {
	sf := NewSeenFile("/tmp/transmission-rss-seen-file-test")
	assert.NotNil(t, sf)

	_, err := os.Stat("/tmp/transmission-rss-seen-file-test")
	assert.Nil(t, err)

	assert.Equal(t, 0, sf.Count())

	sf.Add("example")
	assert.Equal(t, 1, sf.Count())
	assert.True(t, sf.IsPresent("example"))

	sf.Add("example")
	assert.Equal(t, 1, sf.Count())
	assert.True(t, sf.IsPresent("example"))

	sf.Clear()
	assert.Equal(t, 0, sf.Count())

	err = os.Remove("/tmp/transmission-rss-seen-file-test")
	assert.Nil(t, err)
}
