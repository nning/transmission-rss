package aggregator

import (
	"fmt"
	"log"
	"net/http"
	"regexp"

	"github.com/mmcdole/gofeed"

	"github.com/nning/transmission-rss/go/client"
	"github.com/nning/transmission-rss/go/config"
	"github.com/nning/transmission-rss/go/utils"
)

type Aggregator struct {
	Client *client.Client
	Config *config.Config
	Parser *gofeed.Parser
}

func New(config *config.Config) *Aggregator {
	client := client.New(config)

	parser := gofeed.NewParser()
	parser.Client = &http.Client{
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return fmt.Errorf("302")
		},
	}

	self := Aggregator{
		Client: client,
		Config: config,
		Parser: parser,
	}

	return &self
}

func match(title string, expr string) bool {
	re, err := regexp.Compile(expr)
	utils.ExitOnError(err)

	return re.Match([]byte(title))
}

func (a *Aggregator) processItem(feedConfig *config.Feed, item *gofeed.Item) {
	link := item.Link

	if len(item.Enclosures) > 0 {
		link = item.Enclosures[0].URL
	}

	seenFile := a.Config.SeenFile

	if seenFile.IsPresent(link) {
		return
	}

	if !match(item.Title, feedConfig.RegExp) {
		seenFile.Add(link)
		return
	}

	log.Default().Printf("ADD \"%s\"\n", item.Title)
	id, err := a.Client.AddTorrent(link, feedConfig.DownloadPath)
	if err != nil {
		log.Default().Println("ERROR", err)
		return
	}

	seenFile.Add(link)

	if feedConfig.SeedRatioLimit > 0 {
		arguments := make(map[string]interface{})

		arguments["ids"] = []int{id}
		arguments["seedRatioLimit"] = feedConfig.SeedRatioLimit
		arguments["seedRatioMode"] = 1

		a.Client.SetTorrent(arguments)
	}
}

func (a *Aggregator) processFeed(feedConfig *config.Feed) {
	log.Default().Println("FETCH", feedConfig.Url)

	feed, err := a.Parser.ParseURL(feedConfig.Url)

	if err != nil {
		log.Fatal(err)
		return
	}

	for _, item := range feed.Items {
		a.processItem(feedConfig, item)
	}
}

func (a *Aggregator) Run() {
	for _, feedConfig := range a.Config.Feeds {
		a.processFeed(&feedConfig)
	}
}
