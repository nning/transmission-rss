package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_matchesFilters_noFilters(t *testing.T) {
	assert.True(t, matchesFilters("Some Show 1080p", []string{}))
}

func Test_matchesFilters_singleMatch(t *testing.T) {
	assert.True(t, matchesFilters("Some Show 1080p", []string{"1080p"}))
	assert.False(t, matchesFilters("Some Show 720p", []string{"1080p"}))
}

func Test_matchesFilters_multipleFilters_allMatch(t *testing.T) {
	assert.True(t, matchesFilters("Some Show S01E01 1080p", []string{"1080p", "S01E01"}))
}

func Test_matchesFilters_multipleFilters_partialMatch(t *testing.T) {
	assert.False(t, matchesFilters("Some Show S01E01 720p", []string{"1080p", "S01E01"}))
}
