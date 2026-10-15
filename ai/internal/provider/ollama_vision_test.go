package provider

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
)

func stubTextOnlyOllama(t *testing.T) (*httptest.Server, func() []map[string]any) {
	t.Helper()
	var mu sync.Mutex
	var sent []map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/api/show" {
			io.WriteString(w, `{"capabilities":["completion"]}`)
			return
		}
		var req struct {
			Messages []map[string]any `json:"messages"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Errorf("decode request: %v", err)
		}
		mu.Lock()
		sent = req.Messages
		mu.Unlock()
		io.WriteString(w, `{"message":{"content":"ok"},"done":false}`+"\n")
		io.WriteString(w, `{"message":{"content":""},"done":true}`+"\n")
	}))
	return srv, func() []map[string]any {
		mu.Lock()
		defer mu.Unlock()
		return sent
	}
}

func TestOllamaOmitsPastImagesForATextOnlyModel(t *testing.T) {
	srv, sent := stubTextOnlyOllama(t)
	defer srv.Close()

	msgs := []Message{
		{Role: "user", Content: "what is this", Images: []Image{{MediaType: "image/png", Data: "AAAA"}}},
		{Role: "assistant", Content: "a cat"},
		{Role: "user", Content: "and now?"},
	}
	if err := testOllama(srv.URL).Chat(context.Background(), "stub", msgs, ChatOptions{}, func(ChatChunk) error { return nil }); err != nil {
		t.Fatalf("chat: %v", err)
	}

	first := sent()[0]
	if _, ok := first["images"]; ok {
		t.Errorf("past image still sent: %v", first)
	}
	if want := "what is this\n[image omitted: stub cannot see images]"; first["content"] != want {
		t.Errorf("content = %q, want %q", first["content"], want)
	}
	if len(msgs[0].Images) != 1 || msgs[0].Content != "what is this" {
		t.Errorf("caller's message mutated: %+v", msgs[0])
	}
}

func TestOllamaRefusesAnImageInTheCurrentMessage(t *testing.T) {
	srv, sent := stubTextOnlyOllama(t)
	defer srv.Close()

	msgs := []Message{
		{Role: "user", Content: "what is this", Images: []Image{{MediaType: "image/png", Data: "AAAA"}}},
		{Role: "assistant", ToolCalls: []ToolCall{{ID: "c1", Name: "audio_get_volume"}}},
		{Role: "tool", ToolCallID: "c1", Content: "ok"},
	}
	err := testOllama(srv.URL).Chat(context.Background(), "stub", msgs, ChatOptions{}, func(ChatChunk) error { return nil })
	if err == nil || !strings.Contains(err.Error(), "cannot read images") {
		t.Fatalf("err = %v, want a vision refusal", err)
	}
	if sent() != nil {
		t.Errorf("request went out despite the refusal")
	}
}
