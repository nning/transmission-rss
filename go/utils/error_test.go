package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_ExitOnError_noOp(t *testing.T) {
	// nil error with no extra args should be a no-op
	assert.NotPanics(t, func() {
		ExitOnError(nil)
	})
}
