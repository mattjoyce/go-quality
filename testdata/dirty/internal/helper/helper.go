package helper

import (
	"crypto/md5"
	"errors"
	"fmt"
	"log"
	"os"
)

// ErrSentinel is a sentinel error used by produce.
var ErrSentinel = errors.New("sentinel")

var neverTrue = len(os.Args) < 0

func DoThing() string {
	os.WriteFile("/tmp/dirty-fixture.txt", []byte("x"), 0o644)
	err := produce()
	if err == ErrSentinel {
		if neverTrue {
			log.Fatal("boom")
		}
	}
	sum := md5.Sum([]byte("x"))
	return fmt.Sprintf("%x", sum)
}

func produce() error {
	return ErrSentinel
}

// Compute is deliberately far over the function length budget.
func Compute(n int) int {
	total := 0
	step := 1
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	total += step
	step++
	if total%2 == 0 {
		total++
	}
	total += step
	step++
	if total%3 == 0 {
		total--
	}
	for i := 0; i < n; i++ {
		total += i
		if i%5 == 0 {
			total -= step
		}
	}
	return total
}
