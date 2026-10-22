package server

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/tmy7533018/mugen-ai/internal/provider"
)

func TestChatReportsAnUnansweredPromptAsNotDeclined(t *testing.T) {
	del := []provider.ToolCall{{ID: "1", Name: "memory_delete", Arguments: map[string]any{"id": float64(1)}}}
	s, st := newChatServer(t, &turnProvider{rounds: [][]provider.ToolCall{del}})
	s.tools.AttachMemory(st)
	if _, err := st.AddMemory("x"); err != nil {
		t.Fatal(err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		for ctx.Err() == nil {
			s.confirms.mu.Lock()
			n := len(s.confirms.pending)
			s.confirms.mu.Unlock()
			if n > 0 {
				cancel()
				return
			}
			time.Sleep(5 * time.Millisecond)
		}
	}()
	req := httptest.NewRequest(http.MethodPost, "/chat", strings.NewReader(chatJSON(t, "tidy up", 0))).WithContext(ctx)
	req.Header.Set("Content-Type", "application/json")
	s.handleChat(httptest.NewRecorder(), req)

	convs, err := st.ListConversations()
	if err != nil || len(convs) != 1 {
		t.Fatalf("conversations = %d (%v), want 1", len(convs), err)
	}
	msgs, err := st.ListMessages(convs[0].ID)
	if err != nil {
		t.Fatal(err)
	}
	var calls string
	for _, m := range msgs {
		if m.Role == "assistant" {
			calls = string(m.ToolCalls)
		}
	}
	if !strings.Contains(calls, "did not run") || strings.Contains(calls, "declined") {
		t.Errorf("assistant tool calls = %s, want 'did not run' and no 'declined'", calls)
	}
	if mems, err := st.ListMemories(); err != nil || len(mems) != 1 {
		t.Errorf("memory list changed to %d entries (%v)", len(mems), err)
	}
}
