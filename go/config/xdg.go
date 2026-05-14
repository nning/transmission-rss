package config

import (
	"os"
	"os/user"
	"path"
	"strings"
)

func getXDGDir(name string) string {
	dir, isXDG := os.LookupEnv("XDG_" + strings.ToUpper(name) + "_HOME")

	if isXDG {
		return dir
	}

	u, err := user.Current()
	if err != nil {
		return "/"
	}

	return path.Join(u.HomeDir, "."+name, path.Base(os.Args[0]))
}

// GetConfigDir returns XDG config dir
func GetConfigDir() string {
	return getXDGDir("config")
}

// GetCacheDir returns XDG cache dir
func GetCacheDir() string {
	return getXDGDir("cache")
}
