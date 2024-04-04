package client

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/nning/transmission-rss/go/config"
	"github.com/nning/transmission-rss/go/utils"
)

type RequestArguments map[string]interface{}

type RequestBody struct {
	Method    string           `json:"method"`
	Arguments RequestArguments `json:"arguments"`
}

type ResponseBody struct {
	Result    string `json:"result"`
	Arguments struct {
		TorrentAdded struct {
			Id int `json:"id"`
		} `json:"torrent-added"`
		TorrentDuplicate struct {
			Id int `json:"id"`
		} `json:"torrent-duplicate"`
	} `json:"arguments"`
}

type Client struct {
	Config     *config.Config
	httpClient http.Client
	SessionId  string
}

func New(config *config.Config) *Client {
	client := Client{
		Config: config,
		httpClient: http.Client{
			Timeout: 30 * time.Second,
		},
	}

	return &client
}

func getSessionId(config *config.Config) string {
	client := &http.Client{}

	url := config.ServerURL()

	request, err := http.NewRequest("GET", url, nil)
	utils.ExitOnError(err)

	request.SetBasicAuth(config.Login.Username, config.Login.Password)
	response, err := client.Do(request)
	utils.ExitOnError(err)

	_, err = io.ReadAll(response.Body)
	utils.ExitOnError(err)

	if response.StatusCode != 409 {
		status := strconv.Itoa(response.StatusCode)
		utils.ExitOnError(nil, "SESSION_ID ERROR", status)
	}

	sessionId := response.Header["X-Transmission-Session-Id"][0]

	return sessionId
}

func (c *Client) UpdateSessionId() {
	c.SessionId = getSessionId(c.Config)
}

func (c *Client) rpc(requestBody RequestBody) *http.Response {
	url := c.Config.ServerURL()

	jsonData, err := json.Marshal(requestBody)
	utils.ExitOnError(err)

	request, err := http.NewRequest("POST", url, bytes.NewReader(jsonData))
	if err != nil {
		// logger.Error("RPC request error", err)
		return &http.Response{
			StatusCode: 504,
		}
	}

	login := c.Config.Login
	request.SetBasicAuth(login.Username, login.Password)

	request.Header.Add("Content-Type", "application/json")
	request.Header.Add("X-Transmission-Session-Id", c.SessionId)

	response, err := c.httpClient.Do(request)
	utils.ExitOnError(err)

	if response.StatusCode == 409 {
		c.UpdateSessionId()
		response = c.rpc(requestBody)
	}

	return response
}

func (c *Client) AddTorrent(link string, downloadDir string) (id int, err error) {
	var requestBody RequestBody

	requestBody.Method = "torrent-add"
	requestBody.Arguments = make(map[string]interface{})
	requestBody.Arguments["filename"] = link

	if len(downloadDir) > 0 {
		requestBody.Arguments["download-dir"] = downloadDir
	}

	if c.Config.Paused {
		requestBody.Arguments["paused"] = true
	}

	response := c.rpc(requestBody)
	if response.StatusCode != 200 {
		return 0, fmt.Errorf("RPC call error status: %d", response.StatusCode)
	}

	buf := new(bytes.Buffer)
	buf.ReadFrom(response.Body)
	jsonBody := buf.Bytes()

	var jsonResult ResponseBody
	json.Unmarshal(jsonBody, &jsonResult)
	if jsonResult.Result != "success" {
		return 0, errors.New(jsonResult.Result)
	}

	id = jsonResult.Arguments.TorrentAdded.Id
	if id == 0 {
		id = jsonResult.Arguments.TorrentDuplicate.Id
	}

	return id, nil
}

func (c *Client) SetTorrent(arguments RequestArguments) {
	var requestBody RequestBody
	requestBody.Method = "torrent-set"
	requestBody.Arguments = arguments

	c.rpc(requestBody)
}
