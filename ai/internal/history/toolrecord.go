package history

import (
	"encoding/json"
	"fmt"
	"unicode/utf8"

	"github.com/tmy7533018/mugen-ai/internal/attach"
	"github.com/tmy7533018/mugen-ai/internal/provider"
)

// maxReplayResultBytes bounds one replayed tool result so old turns stay cheap in the context.
const maxReplayResultBytes = 2048

// ToolRecord is a tool call stored with its outcome; the client reads the same JSON back on reload.
type ToolRecord struct {
	provider.ToolCall
	Result string `json:"result,omitempty"`
	Error  string `json:"error,omitempty"`
	// Rows written before this field existed have no provider and count as local.
	Provider string `json:"provider,omitempty"`
}

const withheldResult = "(withheld from cloud models: this result may have been fetched by a local model)"

// WithholdLocalResults blanks the replayed results a local model fetched, for a request to a cloud provider.
func WithholdLocalResults(msgs []provider.Message) {
	for i := range msgs {
		if msgs[i].LocalOnly {
			msgs[i].Content = withheldResult
		}
	}
}

// EncodeToolRecords serializes a turn's tool calls for the messages.tool_calls column.
func EncodeToolRecords(recs []ToolRecord) string {
	if len(recs) == 0 {
		return ""
	}
	b, err := json.Marshal(recs)
	if err != nil {
		return ""
	}
	return string(b)
}

func boundReplayResult(s string) string {
	if s == "" {
		return "(no output)"
	}
	if len(s) <= maxReplayResultBytes {
		return s
	}
	n := maxReplayResultBytes
	for i := 0; i < utf8.UTFMax-1 && n > 0 && !utf8.RuneStart(s[n]); i++ {
		n--
	}
	if !utf8.RuneStart(s[n]) {
		n = maxReplayResultBytes
	}
	return s[:n] + fmt.Sprintf("\n[truncated in history: %d of %d bytes omitted]", len(s)-n, len(s))
}

func expandRow(rowID int64, role, content string, toolCalls []byte, att attach.Attachments) []provider.Message {
	single := []provider.Message{{Role: role, Content: att.Prompt(content), Images: att.Images}}
	if role != "assistant" || len(toolCalls) == 0 {
		return single
	}
	var recs []ToolRecord
	if json.Unmarshal(toolCalls, &recs) != nil || len(recs) == 0 {
		return single
	}
	legacy := true
	for _, r := range recs {
		if r.Result != "" || r.Error != "" {
			legacy = false
			break
		}
	}
	if legacy {
		return single
	}

	calls := make([]provider.ToolCall, len(recs))
	results := make([]provider.Message, len(recs))
	for i, r := range recs {
		id := fmt.Sprintf("h%d_%d", rowID, i)
		tc := r.ToolCall
		tc.ID = id
		calls[i] = tc
		results[i] = provider.Message{
			Role:       "tool",
			ToolCallID: id,
			ToolName:   tc.Name,
			Content:    boundReplayResult(r.Result),
			LocalOnly:  r.Provider == "" || r.Provider == "ollama",
		}
	}
	out := make([]provider.Message, 0, len(recs)+2)
	out = append(out, provider.Message{Role: "assistant", ToolCalls: calls})
	out = append(out, results...)
	if content != "" {
		out = append(out, provider.Message{Role: "assistant", Content: content})
	}
	return out
}
