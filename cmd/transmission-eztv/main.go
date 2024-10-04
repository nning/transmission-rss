package main

import (
	"fmt"
	"log"
	"os"
	"path"
	"strings"

	"github.com/nning/transmission-rss/go/client"
	"github.com/nning/transmission-rss/go/config"
	"github.com/nning/transmission-rss/go/eztv"
	"github.com/nning/transmission-rss/go/utils"
)

func main() {
	options := utils.ParseOptions(os.Args)

	if options.IsSet('h') || !options.IsSet('i') {
		fmt.Printf("Usage: %s [options]\n\n", path.Base(os.Args[0]))
		fmt.Printf("Searches for magnet links on eztv and adds them to Transmission web frontend\n\n")
		fmt.Printf("Options:\n")
		fmt.Printf("    -c <path>         path to config file\n")
		fmt.Printf("    -i <imdbID>       IMDb ID [required]\n")
		fmt.Printf("    -f <filter,...>   filters for eztv results\n")
		fmt.Printf("    -d <downloadDir>  download directory\n")
		fmt.Printf("    -h                show this help\n\n")
		os.Exit(0)
	}

	imdbID := options.Get('i')
	filter := options.Get('f')
	filters := strings.Split(filter, ",")
	downloadDir := options.Get('d')

	cfg := config.New(options.Get('c'))

	if cfg.ConfigPath != "" {
		log.Println("CONFIG", cfg.ConfigPath)
	}
	log.Printf("HOST %s:%d\n", cfg.Server.Host, cfg.Server.Port)

	c := client.New(cfg)

	torrents, err := eztv.GetTorrents(imdbID)
	utils.ExitOnError(err)

	var filteredTorrents []eztv.Torrent

	if len(filters) == 0 {
		filteredTorrents = torrents
	} else {
		for _, torrent := range torrents {
			if matchesFilters(torrent.Title, filters) {
				filteredTorrents = append(filteredTorrents, torrent)
			}

		}
	}

	for _, torrent := range filteredTorrents {
		fmt.Println(torrent.Title)

		c.AddTorrent(torrent.MagnetURL, downloadDir)
	}
}

func matchesFilters(title string, filters []string) bool {
	if len(filters) == 0 {
		return true
	}

	for _, filter := range filters {
		if !strings.Contains(title, filter) {
			return false
		}
	}

	return true
}
