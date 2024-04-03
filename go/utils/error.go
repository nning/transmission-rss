package utils

import (
	"log"
	"strings"
)

func ExitOnError(e error, a ...string) {
	if e != nil {
		log.Default().Fatalln(e)
	}

	if len(a) > 0 {
		log.Default().Fatalln(strings.Join(a, " "))
	}
}
