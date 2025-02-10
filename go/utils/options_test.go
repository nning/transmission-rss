package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_ParseOptions(t *testing.T) {
	options := ParseOptions([]string{"cmd", "-a", "-b", "c"})

	assert.Equal(t, 2, len(options.options))
	assert.Equal(t, 0, len(options.Rest))
	assert.True(t, options.IsSet('a'))
	assert.True(t, options.IsSet('b'))
	assert.False(t, options.IsSet('c'))
	assert.Equal(t, "", options.Get('a'))
	assert.Equal(t, "c", options.Get('b'))

	options = ParseOptions([]string{"cmd", "-abc"})
	assert.Equal(t, 3, len(options.options))
	assert.Equal(t, 0, len(options.Rest))
	assert.True(t, options.IsSet('a'))
	assert.True(t, options.IsSet('b'))
	assert.True(t, options.IsSet('c'))
	assert.Equal(t, "", options.Get('a'))
	assert.Equal(t, "", options.Get('b'))
	assert.Equal(t, "", options.Get('c'))

	options = ParseOptions([]string{"cmd", "run"})
	assert.Equal(t, 0, len(options.options))
	assert.Equal(t, 1, len(options.Rest))
	assert.Equal(t, "run", options.Rest[0])

	options = ParseOptions([]string{"cmd", "run", "-a"})

	assert.Equal(t, 1, len(options.options))
	assert.Equal(t, 1, len(options.Rest))
	assert.True(t, options.IsSet('a'))
	assert.False(t, options.IsSet('b'))
	assert.Equal(t, "", options.Get('a'))
	assert.Equal(t, "", options.Get('b'))
	assert.Equal(t, "run", options.Rest[0])

	options = ParseOptions([]string{"cmd", "-abc", "-a", "foo"})
	assert.Equal(t, 3, len(options.options))
	assert.Equal(t, 0, len(options.Rest))
	assert.True(t, options.IsSet('a'))
	assert.True(t, options.IsSet('b'))
	assert.True(t, options.IsSet('c'))
	assert.Equal(t, "foo", options.Get('a'))
	assert.Equal(t, "", options.Get('b'))
	assert.Equal(t, "", options.Get('c'))
}
