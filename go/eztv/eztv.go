package eztv

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"
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

func getTorrents(imdbID string, page int) (*Response, error) {
	p := strconv.Itoa(page)
	url := "https://eztvx.to/api/get-torrents?imdb_id=" + imdbID + "&page=" + p + "&limit=1000"

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)

	var response Response
	err = json.Unmarshal(body, &response)
	if err != nil {
		return nil, err
	}

	return &response, nil
}
