package provider

import (
	"context"
	"testing"
)

func TestLegacyThinkingSkipsAReplayedToolRound(t *testing.T) {
	var bodies [][]byte
	srv := stubAnthropicRounds(t, &bodies)
	defer srv.Close()

	msgs := []Message{
		{Role: "user", Content: "volume?"},
		{Role: "assistant", ToolCalls: []ToolCall{{ID: "h1_0", Name: "audio_get_volume"}}},
		{Role: "tool", ToolCallID: "h1_0", ToolName: "audio_get_volume", Content: "40"},
	}
	err := testAnthropic(srv.URL).Chat(context.Background(), "claude-sonnet-4-5", msgs, ChatOptions{Thinking: true}, func(ChatChunk) error { return nil })
	if err != nil {
		t.Fatalf("chat: %v", err)
	}
	if len(bodies) != 1 {
		t.Fatalf("want exactly 1 request, got %d", len(bodies))
	}
	if thinking, _, _ := requestShape(t, bodies[0]); thinking != nil {
		t.Errorf("thinking field sent: %v", thinking)
	}
}
