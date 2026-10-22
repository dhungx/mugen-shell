package tools

import (
	"context"
	"strings"
	"testing"
)

func TestDesktopCalendarLineCollapsesOnlyPastFiveEvents(t *testing.T) {
	event := func(n int) string {
		return `{"id":"` + string(rune('0'+n)) + `","date":"2026-07-02","time":"1` + string(rune('0'+n)) + `:00","title":"ev` + string(rune('0'+n)) + `"}`
	}
	for _, tc := range []struct {
		n        int
		want     string
		wantMore bool
	}{
		{5, "ev5", false},
		{6, "+2 more", true},
	} {
		results := fullDesktopResults()
		evs := make([]string, tc.n)
		for i := range evs {
			evs[i] = event(i + 1)
		}
		results["calendar"] = `{"events":[` + strings.Join(evs, ",") + `]}`
		r, _, _ := newTestRegistry(t, nil, nil)
		r.run = desktopFakeRun(results)

		var line string
		for _, l := range strings.Split(r.DesktopContext(context.Background()), "\n") {
			if strings.Contains(l, "calendar today:") {
				line = l
			}
		}
		if !strings.Contains(line, tc.want) {
			t.Errorf("n=%d: line %q lacks %q", tc.n, line, tc.want)
		}
		if tc.wantMore != strings.Contains(line, "more") {
			t.Errorf("n=%d: line %q, more present = %v", tc.n, line, !tc.wantMore)
		}
	}
}
