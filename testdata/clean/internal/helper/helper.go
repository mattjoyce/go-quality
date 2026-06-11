// Package helper provides the clean fixture's single operation.
package helper

import (
	"errors"
	"fmt"
)

// ErrEmpty is returned when Run receives an empty name.
var ErrEmpty = errors.New("empty name")

// Run greets the given name, or fails for an empty one.
func Run(name string) (string, error) {
	if name == "" {
		return "", fmt.Errorf("run: %w", ErrEmpty)
	}
	return "hello " + name, nil
}
