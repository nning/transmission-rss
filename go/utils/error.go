package utils

import (
	"log"
	"strings"
)

func ExitOnError(e error, a ...string) {
	if e != nil {
		log.Fatalln(e)
	}

	if len(a) > 0 {
		log.Fatalln(strings.Join(a, " "))
	}
}
