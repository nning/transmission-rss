package utils

import (
	"fmt"
	"os"
)

func ExitOnError(e error, a ...string) {
	if e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}

	if len(a) > 0 {
		fmt.Fprintln(os.Stderr, a[0])
		os.Exit(1)
	}
}
