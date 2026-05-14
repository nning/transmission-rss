package eztv

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"strings"
)

type Torrent struct {
	ID        int    `json:"id"`
	Title     string `json:"title"`
	MagnetURL string `json:"magnet_url"`
}

type Response struct {
	TorrentsCount int       `json:"torrents_count"`
	Limit         int       `json:"limit"`
	Page          int       `json:"page"`
	Torrents      []Torrent `json:"torrents"`
}

func GetTorrents(imdbID string) ([]Torrent, error) {
	var torrents []Torrent

	imdbID = strings.TrimPrefix(imdbID, "tt")

	response, err := getTorrents(imdbID, 1)
	if err != nil {
		return nil, err
	}

	pages := response.TorrentsCount/response.Limit + 1
	torrents = append(torrents, response.Torrents...)

	for p := 2; p <= pages; p++ {
		response, err := getTorrents(imdbID, p)
		if err != nil {
			return nil, err
		}

		torrents = append(torrents, response.Torrents...)
	}

	return torrents, nil
}

var apiBaseURL = "https://eztvx.to/api"

func getTorrents(imdbID string, page int) (*Response, error) {
	p := strconv.Itoa(page)
	url := apiBaseURL + "/get-torrents?imdb_id=" + imdbID + "&page=" + p + "&limit=1000"

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer func() { _ = resp.Body.Close() }()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var response Response
	if err = json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	return &response, nil
}
