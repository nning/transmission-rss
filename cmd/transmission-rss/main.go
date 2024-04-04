package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/nning/transmission-rss/go/aggregator"
	"github.com/nning/transmission-rss/go/config"
)

func main() {
	if len(os.Args) > 1 && os.Args[1] != "-r" {
		fmt.Printf("Usage: transmission-rss [-r]\n\n")
		fmt.Printf("    -r: reset seen file\n\n")
		os.Exit(0)
	}

	c := config.New("")

	if c.ConfigPath != "" {
		log.Default().Println("CONFIG", c.ConfigPath)
	}
	log.Default().Printf("HOST %s:%d\n", c.Server.Host, c.Server.Port)
	log.Default().Println("FEEDS", len(c.Feeds))

	if len(os.Args) > 1 && os.Args[1] == "-r" {
		c.SeenFile.Clear()
	}

	a := aggregator.New(c)
	for {
		a.Run()
		time.Sleep(time.Duration(c.UpdateInterval) * time.Second)
	}
}
