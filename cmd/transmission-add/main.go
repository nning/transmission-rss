package main

import (
	"fmt"
	"log"
	"os"
	"path"

	"github.com/nning/transmission-rss/go/client"
	"github.com/nning/transmission-rss/go/config"
	"github.com/nning/transmission-rss/go/utils"
)

func main() {
	options := utils.ParseOptions(os.Args)

	if options.IsSet('h') || len(os.Args) < 2 {
		fmt.Printf("Usage: %s [options] <path_or_link>...\n\n", path.Base(os.Args[0]))
		fmt.Printf("Adds torrent files or magnet links to Transmission web frontend\n\n")
		fmt.Printf("Options:\n")
		fmt.Printf("    -c <path>    path to config file\n")
		fmt.Printf("    -h           show this help\n")
		os.Exit(0)
	}

	cfg := config.New(options.Get('c'))

	if cfg.ConfigPath != "" {
		log.Println("CONFIG", cfg.ConfigPath)
	}
	log.Printf("HOST %s:%d\n", cfg.Server.Host, cfg.Server.Port)

	c := client.New(cfg)

	for _, source := range options.Rest {
		log.Println(source)
		_, err := c.AddTorrent(source, "")

		if err != nil {
			log.Println("ERROR", err)
		} else {
			log.Printf("ADD \"%s\"\n", source)
		}
	}
}
