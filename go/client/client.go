package client

type Client struct {
	url string
}

func New(url string) *Client {
	return &Client{url: url}
}
