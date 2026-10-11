package tools

import (
	"fmt"

	"github.com/tmy7533018/mugen-ai/internal/calendar"
)

// ConfirmTarget describes what a held call would act on, or returns "" when there is nothing to look up.
func (r *Registry) ConfirmTarget(name string, args map[string]any) string {
	switch name {
	case "memory_delete":
		return r.memoryTarget(args)
	case "calendar_delete":
		return r.calendarTarget(args)
	}
	return ""
}

func (r *Registry) memoryTarget(args map[string]any) string {
	id, ok := toInt64(args["id"])
	if !ok || r.memStore == nil {
		return ""
	}
	mems, err := r.memStore.ListMemories()
	if err != nil {
		return ""
	}
	for _, m := range mems {
		if m.ID == id {
			return fmt.Sprintf("#%d %s", id, oneLine(m.Content))
		}
	}
	return fmt.Sprintf("no memory with id %d", id)
}

func (r *Registry) calendarTarget(args map[string]any) string {
	id, ok := args["id"].(string)
	if !ok || id == "" {
		return ""
	}
	st, err := calendar.Open(r.calendarPath)
	if err != nil {
		return ""
	}
	defer st.Close()
	ev, found, err := st.Get(id)
	if err != nil {
		return ""
	}
	if !found {
		return "no event with that id"
	}
	if ev.Time == "" {
		return ev.Date + " (all day) " + ev.Title
	}
	return ev.Date + " " + ev.Time + " " + ev.Title
}
