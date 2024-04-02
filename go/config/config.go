package config

import (
	"fmt"
	"os"
	"path"

	"net/url"

	"github.com/nning/transmission-rss/go/utils"
	"gopkg.in/yaml.v3"
)

type Feed struct {
	Url            string  `yaml:"url"`
	RegExp         string  `yaml:"regexp"`
	SeedRatioLimit float32 `yaml:"seed_ratio_limit"`
	DownloadPath   string  `yaml:"download_path"`
}

type Config struct {
	Feeds []Feed `yaml:"feeds"`

	Server struct {
		Host    string `yaml:"host"`
		Port    int    `yaml:"port"`
		Tls     bool   `yaml:"tls"`
		RpcPath string `yaml:"rpc_path"`
	} `yaml:"server"`

	Login struct {
		Username string `yaml:"username"`
		Password string `yaml:"password"`
	} `yaml:"login"`

	UpdateInterval int `yaml:"update_interval"`

	Paused bool `yaml:"add_paused"`
}

func New(configPath string) *Config {
	if configPath == "" {
		configPath = getPath()
	}

	var config Config

	if configPath != "" {
		yamlData, err := os.ReadFile(configPath)
		utils.ExitOnError(err)

		err = yaml.Unmarshal(yamlData, &config)
		utils.ExitOnError(err)
	}

	config.UpdateInterval = DefaultInt(config.UpdateInterval, 600)
	config.Server.Host = DefaultString(config.Server.Host, "localhost")
	config.Server.RpcPath = DefaultString(config.Server.RpcPath, "/transmission/rpc")
	config.Server.Port = DefaultInt(config.Server.Port, 9091)

	return &config
}

func getPath() string {
	workDir, _ := os.Getwd()

	configDirs := []string{
		workDir,
		path.Dir(os.Args[0]),
		utils.GetConfigDir(),
	}

	fileNames := []string{
		"config",
		path.Base(os.Args[0]),
	}

	extensions := []string{
		".yml",
		".yaml",
		".conf",
	}

	for _, d := range configDirs {
		for _, f := range fileNames {
			for _, e := range extensions {
				p := path.Join(d, f+e)
				if _, err := os.Stat(p); err == nil {
					fmt.Println("Using config file: ", p)
					return p
				}
			}
		}
	}

	return ""
}

func (config *Config) ServerURL() string {
	uri := url.URL{
		Host: fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port),
		Path: config.Server.RpcPath,
	}

	if config.Server.Tls {
		uri.Scheme = "https"
	} else {
		uri.Scheme = "http"
	}

	return uri.String()
}
