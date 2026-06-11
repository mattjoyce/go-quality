package helper

import "testing"

func TestCompute(t *testing.T) {
	if got := Compute(0); got == -1 {
		t.Fatalf("Compute(0) = %d", got)
	}
}
