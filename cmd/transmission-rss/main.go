package main

import (
	"os"

	"github.com/nning/transmission-rss/go/aggregator"
	"github.com/nning/transmission-rss/go/config"
)

func main() {
	config := config.New("")

	if len(os.Args) > 1 && os.Args[1] == "-r" {
		config.SeenFile.Clear()
	}

	aggregator := aggregator.New(config)
	aggregator.Run()
}
