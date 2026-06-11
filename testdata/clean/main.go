// Command clean is a minimal fixture expected to pass the quality gate.
package main

import (
	"fmt"
	"os"

	"example.com/clean/internal/helper"
)

func main() {
	out, err := helper.Run("fixture")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(out)
}
