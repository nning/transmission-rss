package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/nning/transmission-rss/go/aggregator"
	"github.com/nning/transmission-rss/go/config"
)

// Version is set during build
var Version string

// Buildtime is set during build
var Buildtime string

func main() {
	if len(os.Args) > 1 && os.Args[1] != "-r" {
		fmt.Printf("Usage: transmission-rss [-r]\n\n")
		fmt.Printf("    -r: reset seen file\n\n")
		fmt.Printf("Version:  %s\nBuild:    %s\n\n", Version, Buildtime)
		os.Exit(0)
	}

	c := config.New("")
	log.Default().Println("CONFIG", c.ConfigPath)

	if len(os.Args) > 1 && os.Args[1] == "-r" {
		c.SeenFile.Clear()
	}

	a := aggregator.New(c)
	for {
		a.Run()
		time.Sleep(time.Duration(c.UpdateInterval) * time.Second)
	}
}
