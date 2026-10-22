package art

import (
	"errors"
	"testing"
)

func TestACoverPastTheCapIsRejectedButOneBelowIsNot(t *testing.T) {
	if _, err := DominantColor(declaredCanvasPNG(t, 7000, 7000)); !errors.Is(err, errTooLarge) {
		t.Errorf("7000x7000 error = %v, want %v", err, errTooLarge)
	}
	if _, err := DominantColor(declaredCanvasPNG(t, 6000, 6000)); errors.Is(err, errTooLarge) {
		t.Errorf("6000x6000 rejected as too large")
	}
}
