package utils

import (
	"fmt"
	"os"
	"os/user"
	"path"
	"strings"
)

func getXDGDir(name string) string {
	dir, isXDG := os.LookupEnv("XDG_" + strings.ToUpper(name) + "_HOME")
	if !isXDG {
		u, _ := user.Current()
		dir = path.Join(u.HomeDir, "."+name, "transmission-rss")

		binName := path.Base(os.Args[0])
		fmt.Println(binName)
	}

	return dir
}

// GetConfigDir returns XDG config dir
func GetConfigDir() string {
	return getXDGDir("config")
}

// GetCacheDir returns XDG cache dir
func GetCacheDir() string {
	return getXDGDir("cache")
}
