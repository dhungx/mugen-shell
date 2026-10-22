package provider

import (
	"context"
	"slices"
	"testing"
	"time"
)

type listingProvider struct {
	name   string
	models []string
	delay  time.Duration
}

func (p *listingProvider) Name() string              { return p.name }
func (p *listingProvider) Ping(context.Context) bool { return true }
func (p *listingProvider) Chat(context.Context, string, []Message, ChatOptions, func(ChatChunk) error) error {
	return nil
}
func (p *listingProvider) Models(ctx context.Context) ([]string, error) {
	select {
	case <-time.After(p.delay):
		return p.models, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func TestModelsKeepsProviderOrderWhenTheFirstAnswersLast(t *testing.T) {
	r := NewRegistry("",
		&listingProvider{name: "slow", models: []string{"a1", "a2"}, delay: 50 * time.Millisecond},
		&listingProvider{name: "fast", models: []string{"b1"}},
	)
	got, _ := r.Models(context.Background())
	if !slices.Equal(got, []string{"a1", "a2", "b1"}) {
		t.Fatalf("Models = %v", got)
	}
	if m := r.EnsureModel(context.Background()); m != "a1" {
		t.Fatalf("EnsureModel adopted %q, want the first provider's first model", m)
	}
}

func TestRoutingDoesNotWaitOnALaterProviderThatHangs(t *testing.T) {
	r := NewRegistry("a1",
		&listingProvider{name: "first", models: []string{"a1"}},
		&listingProvider{name: "hung", delay: time.Hour},
	)
	start := time.Now()
	if got := r.ProviderNameFor(context.Background(), "a1"); got != "first" {
		t.Fatalf("ProviderNameFor = %q", got)
	}
	if elapsed := time.Since(start); elapsed > time.Second {
		t.Fatalf("routing took %v waiting on a provider listed after the match", elapsed)
	}
}
