package tools

import (
	"path/filepath"
	"testing"

	"github.com/tmy7533018/mugen-ai/internal/calendar"
)

func TestConfirmTargetMemory(t *testing.T) {
	r, st := newMemoryRegistry(t, nil)
	if _, err := st.AddMemory("User prefers dark mode"); err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name string
		args map[string]any
		want string
	}{
		{"found", map[string]any{"id": float64(1)}, "#1 User prefers dark mode"},
		{"missing", map[string]any{"id": float64(9)}, "no memory with id 9"},
		{"bad id", map[string]any{"id": "x"}, ""},
		{"no id", map[string]any{}, ""},
	}
	for _, c := range cases {
		if got := r.ConfirmTarget("memory_delete", c.args); got != c.want {
			t.Errorf("%s: got %q, want %q", c.name, got, c.want)
		}
	}
	if got := r.ConfirmTarget("memory_save", map[string]any{"id": float64(1)}); got != "" {
		t.Errorf("other tool: got %q", got)
	}
}

func TestConfirmTargetCalendar(t *testing.T) {
	path := filepath.Join(t.TempDir(), "cal.db")
	st, err := calendar.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	timed, err := st.Add("2026-10-12", "09:30", "standup")
	if err != nil {
		t.Fatal(err)
	}
	allDay, err := st.Add("2026-10-13", "", "holiday")
	if err != nil {
		t.Fatal(err)
	}
	st.Close()

	r, _, _ := newTestRegistry(t, nil, nil)
	r.calendarPath = path
	cases := []struct {
		name string
		args map[string]any
		want string
	}{
		{"timed", map[string]any{"id": timed}, "2026-10-12 09:30 standup"},
		{"all day", map[string]any{"id": allDay}, "2026-10-13 (all day) holiday"},
		{"missing", map[string]any{"id": "nope"}, "no event with that id"},
		{"empty id", map[string]any{"id": ""}, ""},
		{"non-string id", map[string]any{"id": 3}, ""},
	}
	for _, c := range cases {
		if got := r.ConfirmTarget("calendar_delete", c.args); got != c.want {
			t.Errorf("%s: got %q, want %q", c.name, got, c.want)
		}
	}
}
