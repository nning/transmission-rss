package config

import (
	"os"
	"strconv"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_NewSeenFile(t *testing.T) {
	sf := NewSeenFile(0, "/tmp/transmission-rss-seen-file-test")
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

func countLines(t *testing.T, path string) int {
	content, err := os.ReadFile(path)
	assert.Nil(t, err)

	return len(strings.Split(strings.TrimRight(string(content), "\n"), "\n"))
}

func Test_SeenFileLimit(t *testing.T) {
	path := "/tmp/transmission-rss-seen-file-limit-test"
	defer func() { _ = os.Remove(path) }()

	limit := 10
	count := 25
	last := strconv.Itoa(count - 1)

	sf := NewSeenFile(limit, path)

	for i := 0; i < count; i++ {
		sf.Add(strconv.Itoa(i))
	}

	assert.Equal(t, limit, sf.Count())
	assert.False(t, sf.IsPresent("0"))
	assert.True(t, sf.IsPresent(last))

	assert.LessOrEqual(t, countLines(t, path), limit+compactionSlack(limit))

	sf = NewSeenFile(limit, path)
	assert.Equal(t, limit, sf.Count())
	assert.True(t, sf.IsPresent(last))
	assert.Equal(t, limit, countLines(t, path))
}

func Test_SeenFileLimitTrimsExistingFile(t *testing.T) {
	path := "/tmp/transmission-rss-seen-file-trim-test"
	defer func() { _ = os.Remove(path) }()

	sf := NewSeenFile(0, path)
	for i := 0; i < 100; i++ {
		sf.Add(strconv.Itoa(i))
	}
	assert.Equal(t, 100, sf.Count())

	sf = NewSeenFile(10, path)
	assert.Equal(t, 10, sf.Count())
	assert.False(t, sf.IsPresent("89"))
	assert.True(t, sf.IsPresent("90"))
	assert.True(t, sf.IsPresent("99"))
	assert.Equal(t, 10, countLines(t, path))
}

func Test_SeenFileUnlimited(t *testing.T) {
	path := "/tmp/transmission-rss-seen-file-unlimited-test"
	defer func() { _ = os.Remove(path) }()

	sf := NewSeenFile(-1, path)
	for i := 0; i < 2000; i++ {
		sf.Add(strconv.Itoa(i))
	}

	assert.Equal(t, 2000, sf.Count())
	assert.True(t, sf.IsPresent("0"))
	assert.Equal(t, 2000, countLines(t, path))
}
