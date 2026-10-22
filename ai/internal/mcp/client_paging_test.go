package mcp

import (
	"fmt"
	"strings"
	"testing"
)

func TestClientListToolsStopsOnARepeatedCursor(t *testing.T) {
	tr := newScriptedTransport(func(req rpcMessage) (rpcMessage, bool) {
		if req.Method != "tools/list" {
			return rpcMessage{}, false
		}
		return resultMsg(map[string]any{
			"tools":      []map[string]any{{"name": "alpha"}},
			"nextCursor": "same",
		}), true
	})
	c := newClient("test", tr, false)
	defer c.Close()

	_, err := c.ListTools(testCtx(t))
	if err == nil || !strings.Contains(err.Error(), "repeated cursor") {
		t.Fatalf("err = %v, want repeated cursor", err)
	}
	if n := len(tr.sentMethods()); n != 2 {
		t.Fatalf("sent %d requests, want 2", n)
	}
}

func TestClientListToolsCapsTheWholeCatalog(t *testing.T) {
	old := recvCap
	recvCap = 4096
	defer func() { recvCap = old }()

	page := 0
	tr := newScriptedTransport(func(req rpcMessage) (rpcMessage, bool) {
		if req.Method != "tools/list" {
			return rpcMessage{}, false
		}
		page++
		return resultMsg(map[string]any{
			"tools":      []map[string]any{{"name": fmt.Sprintf("t%d", page)}},
			"nextCursor": fmt.Sprintf("p%d", page),
		}), true
	})
	c := newClient("test", tr, false)
	defer c.Close()

	_, err := c.ListTools(testCtx(t))
	if err == nil || !strings.Contains(err.Error(), "exceeds") {
		t.Fatalf("err = %v, want exceeds", err)
	}
}
