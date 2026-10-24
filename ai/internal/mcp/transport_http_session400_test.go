package mcp

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func sessionServerAnswering400(body, contentType string) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Mcp-Session-Id") == "" {
			w.Header().Set("Mcp-Session-Id", "s1")
			w.Header().Set("Content-Type", "application/json")
			_, _ = io.WriteString(w, `{"jsonrpc":"2.0","id":1,"result":{}}`)
			return
		}
		reqBody, _ := io.ReadAll(r.Body)
		if strings.Contains(string(reqBody), `"ping"`) {
			w.Header().Set("Content-Type", "application/json")
			_, _ = io.WriteString(w, `{"jsonrpc":"2.0","id":3,"result":{}}`)
			return
		}
		w.Header().Set("Content-Type", contentType)
		w.WriteHeader(http.StatusBadRequest)
		_, _ = io.WriteString(w, body)
	}))
}

func TestHTTPTransportKeepsItsSessionOnAPerMessage400(t *testing.T) {
	for name, body := range map[string]string{
		"ts-sdk parse error":    `{"jsonrpc":"2.0","error":{"code":-32700,"message":"Parse error","data":"TypeError: x"},"id":null}`,
		"python-sdk validation": `{"jsonrpc":"2.0","id":"server-error","error":{"code":-32602,"message":"Validation error: x"}}`,
	} {
		t.Run(name, func(t *testing.T) {
			ts := sessionServerAnswering400(body, "application/json")
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
			got, err := recvResult(t, tr)
			if err != nil {
				t.Fatalf("a 400 about the message broke the transport: %v", err)
			}
			if !strings.Contains(string(got), `"id":2`) || !strings.Contains(string(got), `"error"`) {
				t.Fatalf("expected a JSON-RPC error for id 2, got: %s", got)
			}
			if err := tr.send(context.Background(), []byte(`{"jsonrpc":"2.0","id":3,"method":"ping"}`)); err != nil {
				t.Fatal(err)
			}
			if got := recvWithTimeout(t, tr); !strings.Contains(string(got), `"result"`) {
				t.Fatalf("the session should still serve the next call, got: %s", got)
			}
		})
	}
}

func TestHTTPTransportBreaksOnEverySDKsStaleSession400(t *testing.T) {
	for name, tc := range map[string]struct{ body, ct string }{
		"python-sdk < 1.26":       {"Bad Request: No valid session ID provided", "text/plain; charset=utf-8"},
		"ts-sdk example server":   {`{"jsonrpc":"2.0","error":{"code":-32000,"message":"Bad Request: No valid session ID provided"},"id":null}`, "application/json"},
		"ts-sdk restarted server": {`{"jsonrpc":"2.0","error":{"code":-32000,"message":"Bad Request: Server not initialized"},"id":null}`, "application/json"},
		"session-shaped -32600":   {`{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Session not found"}}`, "application/json"},
	} {
		t.Run(name, func(t *testing.T) {
			ts := sessionServerAnswering400(tc.body, tc.ct)
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
		})
	}
}
