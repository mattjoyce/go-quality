package helper

import (
	"errors"
	"testing"
)

func TestRun(t *testing.T) {
	tests := []struct {
		name    string
		in      string
		want    string
		wantErr error
	}{
		{name: "greets", in: "go", want: "hello go"},
		{name: "rejects empty", in: "", wantErr: ErrEmpty},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Run(tt.in)
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("Run(%q) error = %v, want %v", tt.in, err, tt.wantErr)
			}
			if got != tt.want {
				t.Fatalf("Run(%q) = %q, want %q", tt.in, got, tt.want)
			}
		})
	}
}
