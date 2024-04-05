package main

import (
	"fmt"
	"log"
	"os"
	"path"
	"time"

	"github.com/nning/transmission-rss/go/aggregator"
	"github.com/nning/transmission-rss/go/config"
	"github.com/nning/transmission-rss/go/utils"
)

func main() {
	options := utils.ParseOptions(os.Args)

	if options.IsSet('h') {
		fmt.Printf("Usage: %s [options]\n\n", path.Base(os.Args[0]))
		fmt.Printf("Adds torrents from RSS feeds to Transmission web frontend\n\n")
		fmt.Printf("Options:\n")
		fmt.Printf("    -c <path>    path to config file\n")
		fmt.Printf("    -h           show this help\n")
		fmt.Printf("    -r           reset seen file\n")
		fmt.Printf("    -s           single run\n\n")
		os.Exit(0)
	}

	c := config.New(options.Get('c'))

	if c.ConfigPath != "" {
		log.Println("CONFIG", c.ConfigPath)
	}
	log.Printf("HOST %s:%d\n", c.Server.Host, c.Server.Port)
	log.Println("FEEDS", len(c.Feeds))

	if options.IsSet('r') {
		c.SeenFile.Clear()
	}

	a := aggregator.New(c)

	if options.IsSet('s') {
		a.Run()
	} else {
		for {
			a.Run()
			time.Sleep(time.Duration(c.UpdateInterval) * time.Second)
		}
	}
}
