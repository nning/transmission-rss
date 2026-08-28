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

const DefaultSeenLimit = 10000

func compactionSlack(limit int) int {
	if slack := limit / 100; slack > 1 {
		return slack
	}

	return 1
}

type SeenFile struct {
	Path  string
	Items []string
	Limit int
	lines int
}

func NewSeenFile(limit int, params ...string) *SeenFile {
	var seenPath string

	if len(params) == 0 {
		seenPath = path.Join(GetConfigDir(), "seen")
		utils.ExitOnError(os.MkdirAll(path.Dir(seenPath), 0700))
	} else {
		seenPath = params[0]
	}

	file, err := os.OpenFile(seenPath, os.O_RDONLY|os.O_CREATE, 0600)
	utils.ExitOnError(err)

	defer func() { _ = file.Close() }()

	var items []string

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		items = append(items, scanner.Text())
	}

	log.Println("SEEN " + strconv.Itoa(len(items)) + " items")

	s := SeenFile{
		Path:  seenPath,
		Items: items,
		Limit: limit,
		lines: len(items),
	}

	if dropped := s.trim(); dropped > 0 {
		log.Println("SEEN dropping " + strconv.Itoa(dropped) +
			" items over limit of " + strconv.Itoa(limit))
	}

	if s.lines > len(s.Items) {
		utils.ExitOnError(s.rewrite())
		s.lines = len(s.Items)
	}

	return &s
}

func (s *SeenFile) Add(link string) {
	hash := sha256sum(link)

	if s.IsPresent(link) {
		return
	}

	s.Items = append(s.Items, hash)
	s.appendItem(hash)

	s.trim()
	s.compact()
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
	s.lines = 0

	err := os.Truncate(s.Path, 0)
	utils.ExitOnError(err)
}

func (s *SeenFile) appendItem(hash string) {
	file, err := os.OpenFile(s.Path, os.O_APPEND|os.O_WRONLY, 0600)
	utils.ExitOnError(err)
	defer func() { _ = file.Close() }()

	_, err = file.Write([]byte(hash + "\n"))
	utils.ExitOnError(err)

	s.lines++
}

func (s *SeenFile) trim() int {
	if s.Limit < 1 || len(s.Items) <= s.Limit {
		return 0
	}

	dropped := len(s.Items) - s.Limit
	s.Items = append([]string{}, s.Items[dropped:]...)

	return dropped
}

func (s *SeenFile) compact() {
	if s.Limit < 1 || s.lines <= s.Limit+compactionSlack(s.Limit) {
		return
	}

	utils.ExitOnError(s.rewrite())
	s.lines = len(s.Items)
}

func (s *SeenFile) rewrite() error {
	file, err := os.CreateTemp(path.Dir(s.Path), path.Base(s.Path)+".*")
	if err != nil {
		return err
	}

	tmpPath := file.Name()

	discard := func(err error) error {
		_ = file.Close()
		_ = os.Remove(tmpPath)

		return err
	}

	writer := bufio.NewWriter(file)

	for _, item := range s.Items {
		if _, err := writer.WriteString(item + "\n"); err != nil {
			return discard(err)
		}
	}

	if err := writer.Flush(); err != nil {
		return discard(err)
	}

	if err := file.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}

	if err := os.Rename(tmpPath, s.Path); err != nil {
		_ = os.Remove(tmpPath)
		return err
	}

	return nil
}

func sha256sum(input string) string {
	hash := sha256.New()
	hash.Write([]byte(input))
	return fmt.Sprintf("%x", hash.Sum(nil))
}
