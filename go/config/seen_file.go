package config

import (
	"bufio"
	"crypto/sha256"
	"fmt"
	"log"
	"os"
	"path"
	"strconv"

	"github.com/nning/transmission-rss/go/utils"
)

type SeenFile struct {
	Path  string
	Items []string
}

func NewSeenFile(params ...string) *SeenFile {
	var seenPath string

	if len(params) == 0 {
		seenPath = path.Join(GetConfigDir(), "seen")
		os.MkdirAll(path.Dir(seenPath), 0700)
	} else {
		seenPath = params[0]
	}

	file, err := os.OpenFile(seenPath, os.O_RDONLY|os.O_CREATE, 0600)
	utils.ExitOnError(err)

	defer file.Close()

	var items []string

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		items = append(items, scanner.Text())
	}

	log.Println("SEEN " + strconv.Itoa(len(items)) + " items")

	s := SeenFile{
		Path:  seenPath,
		Items: items,
	}

	return &s
}

func (s *SeenFile) Add(link string) {
	hash := sha256sum(link)

	if s.IsPresent(link) {
		return
	}

	s.Items = append(s.Items, hash)

	file, err := os.OpenFile(s.Path, os.O_APPEND|os.O_WRONLY, 0600)
	utils.ExitOnError(err)
	defer file.Close()

	_, err = file.Write([]byte(hash + "\n"))
	utils.ExitOnError(err)

	file.Close()
}

func (s *SeenFile) IsPresent(link string) bool {
	for _, item := range s.Items {
		if item == sha256sum(link) {
			return true
		}
	}

	return false
}

func (s *SeenFile) Count() int {
	return len(s.Items)
}

func (s *SeenFile) Clear() {
	s.Items = []string{}

	err := os.Truncate(s.Path, 0)
	utils.ExitOnError(err)
}

func sha256sum(input string) string {
	hash := sha256.New()
	hash.Write([]byte(input))
	return fmt.Sprintf("%x", hash.Sum(nil))
}
