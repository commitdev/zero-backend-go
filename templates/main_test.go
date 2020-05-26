package main_test

import (
	"testing"
)

func TestExample(t *testing.T) {
	got := (1 + 1)
	if got != 2 {
		t.Errorf("1 + 1 = %d; want 2", got)
	}
}