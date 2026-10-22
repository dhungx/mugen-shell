package mcp

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
)

func TestHTTPTransportBreaksOnA400ForItsSession(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Mcp-Session-Id") != "" {
			http.Error(w, "no valid session", http.StatusBadRequest)
			return
		}
		w.Header().Set("Mcp-Session-Id", "s1")
		w.Header().Set("Content-Type", "application/json")
		_, _ = io.WriteString(w, `{"jsonrpc":"2.0","id":1,"result":{}}`)
	}))
	defer ts.Close()

	tr, err := newHTTPTransport("test", ts.URL)
	if err != nil {
		t.Fatal(err)
	}
	defer tr.close()

	if err := tr.send(context.Background(), []byte(`{"jsonrpc":"2.0","id":1,"method":"initialize"}`)); err != nil {
		t.Fatal(err)
	}
	recvWithTimeout(t, tr)
	if err := tr.send(context.Background(), []byte(`{"jsonrpc":"2.0","id":2,"method":"tools/call"}`)); err != nil {
		t.Fatal(err)
	}
	if _, err := recvResult(t, tr); err == nil {
		t.Error("expected recv to report the rejected session")
	}
}

func TestHTTPTransportKeepsASessionless400ToThatCall(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "bad request", http.StatusBadRequest)
	}))
	defer ts.Close()

	tr, err := newHTTPTransport("test", ts.URL)
	if err != nil {
		t.Fatal(err)
	}
	defer tr.close()

	if err := tr.send(context.Background(), []byte(`{"jsonrpc":"2.0","id":9,"method":"ping"}`)); err != nil {
		t.Fatal(err)
	}
	got := recvWithTimeout(t, tr)
	if !strings.Contains(string(got), `"error"`) || !strings.Contains(string(got), `"id":9`) {
		t.Errorf("expected synthesized JSON-RPC error for id 9, got: %s", got)
	}
}

// Mimics python-sdk < 1.26: an unknown Mcp-Session-Id gets 400 instead of 404.
type staleSessionServer struct {
	mu       sync.Mutex
	gen      int
	sessions map[string]bool
}

func (s *staleSessionServer) restart() {
	s.mu.Lock()
	s.gen++
	s.sessions = map[string]bool{}
	s.mu.Unlock()
}

func (s *staleSessionServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	body, _ := io.ReadAll(r.Body)
	var msg struct {
		ID     json.RawMessage `json:"id"`
		Method string          `json:"method"`
	}
	_ = json.Unmarshal(body, &msg)
	sid := r.Header.Get("Mcp-Session-Id")
	s.mu.Lock()
	defer s.mu.Unlock()
	if sid == "" {
		if msg.Method != "initialize" {
			http.Error(w, "Missing session ID", http.StatusBadRequest)
			return
		}
		sid = fmt.Sprintf("sess-%d", s.gen)
		s.sessions[sid] = true
		w.Header().Set("Mcp-Session-Id", sid)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"jsonrpc":"2.0","id":%s,"result":{"protocolVersion":"2025-06-18","capabilities":{},"serverInfo":{"name":"x","version":"1"}}}`, msg.ID)
		return
	}
	if !s.sessions[sid] {
		http.Error(w, "No valid session ID provided", http.StatusBadRequest)
		return
	}
	if len(msg.ID) == 0 {
		w.WriteHeader(http.StatusAccepted)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	switch msg.Method {
	case "tools/list":
		fmt.Fprintf(w, `{"jsonrpc":"2.0","id":%s,"result":{"tools":[{"name":"get_x","inputSchema":{"type":"object"}}]}}`, msg.ID)
	case "tools/call":
		fmt.Fprintf(w, `{"jsonrpc":"2.0","id":%s,"result":{"content":[{"type":"text","text":"ok-%d"}]}}`, msg.ID, s.gen)
	}
}

func TestManagerRedialsWhenARestartedServerRejectsTheOldSessionWith400(t *testing.T) {
	srv := &staleSessionServer{sessions: map[string]bool{}}
	ts := httptest.NewServer(srv)
	defer ts.Close()
	m := Connect(context.Background(), map[string]ServerConfig{"py": {URL: ts.URL}})
	defer m.Close()

	if out, err := m.Call(context.Background(), "py", "get_x", nil); err != nil || out != "ok-0" {
		t.Fatalf("before restart: out=%q err=%v", out, err)
	}
	srv.restart()
	out, err := m.Call(context.Background(), "py", "get_x", nil)
	if err != nil || out != "ok-1" {
		t.Fatalf("after restart: out=%q err=%v", out, err)
	}
}
