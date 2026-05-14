package eztv

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/stretchr/testify/assert"
)

func withTestServer(handler http.HandlerFunc, fn func(baseURL string)) {
	server := httptest.NewServer(handler)
	defer server.Close()

	original := apiBaseURL
	apiBaseURL = server.URL
	defer func() { apiBaseURL = original }()

	fn(server.URL)
}

func Test_GetTorrents_singlePage(t *testing.T) {
	withTestServer(func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(Response{
			Limit:         1000,
			Page:          1,
			Torrents: []Torrent{
				{ID: 1, Title: "Show S01E01", MagnetURL: "magnet:?xt=1"},
				{ID: 2, Title: "Show S01E02", MagnetURL: "magnet:?xt=2"},
			},
		})
	}, func(_ string) {
		torrents, err := GetTorrents("1234567")

		assert.Nil(t, err)
		assert.Len(t, torrents, 2)
		assert.Equal(t, "Show S01E01", torrents[0].Title)
		assert.Equal(t, "Show S01E02", torrents[1].Title)
	})
}

func Test_GetTorrents_multiPage(t *testing.T) {
	page := 0

	withTestServer(func(w http.ResponseWriter, r *http.Request) {
		page++
		torrents := []Torrent{{ID: page, Title: "Show", MagnetURL: "magnet:?xt=" + r.URL.Query().Get("page")}}
		_ = json.NewEncoder(w).Encode(Response{
			TorrentsCount: 3,
			Limit:         2,
			Page:          page,
			Torrents:      torrents,
		})
	}, func(_ string) {
		torrents, err := GetTorrents("1234567")

		assert.Nil(t, err)
		// pages = 3/2 + 1 = 2, so 2 requests → 2 torrents
		assert.Len(t, torrents, 2)
	})
}

func Test_GetTorrents_imdbIDPrefix(t *testing.T) {
	var receivedImdbID string

	withTestServer(func(w http.ResponseWriter, r *http.Request) {
		u, _ := url.Parse(r.RequestURI)
		receivedImdbID = u.Query().Get("imdb_id")
		_ = json.NewEncoder(w).Encode(Response{TorrentsCount: 0, Limit: 1000, Page: 1})
	}, func(_ string) {
		_, _ = GetTorrents("tt1234567")

		assert.Equal(t, "1234567", receivedImdbID)
	})
}

func Test_getTorrents_invalidJSON(t *testing.T) {
	withTestServer(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("not json"))
	}, func(_ string) {
		_, err := getTorrents("1234567", 1)
		assert.NotNil(t, err)
	})
}
