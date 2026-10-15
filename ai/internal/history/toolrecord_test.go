package history

import "testing"

func TestToolOnlyRowWithEmptyResultStillReplays(t *testing.T) {
	h, _ := newTestHistory(t)
	convID, _ := h.NewConversation("m", false)
	recs := toolRecords("", "")
	for i := range recs {
		recs[i].Provider = "anthropic"
	}
	addToolTurn(t, h, "q", "", recs)

	msgs := reloaded(t, h, convID)
	if len(msgs) < 4 || len(msgs[1].ToolCalls) != 2 || msgs[2].Role != "tool" || msgs[2].Content != "(no output)" {
		t.Fatalf("tool round dropped from replay: %+v", msgs)
	}
}
