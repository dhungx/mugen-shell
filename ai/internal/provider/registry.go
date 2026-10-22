package provider

import (
	"context"
	"fmt"
	"slices"
	"sync"
	"time"
)

// Bounds each model-listing probe so a hung backend can't stall a chat routed elsewhere.
const providerProbeTimeout = 5 * time.Second

type Registry struct {
	mu        sync.RWMutex
	providers []Provider
	model     string
	// A model's owning provider doesn't change at runtime, so entries never need invalidation.
	routeCache map[string]Provider
}

func NewRegistry(model string, providers ...Provider) *Registry {
	return &Registry{model: model, providers: providers, routeCache: map[string]Provider{}}
}

func (r *Registry) SetModel(model string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.model = model
}

func (r *Registry) Model() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.model
}

// EnsureModel returns the current model, adopting the first listed one when
// none is set. It only lists models while the registry has none.
func (r *Registry) EnsureModel(ctx context.Context) string {
	if m := r.Model(); m != "" {
		return m
	}
	models, _ := r.Models(ctx)
	if len(models) == 0 {
		return ""
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.model == "" {
		r.model = models[0]
	}
	return r.model
}

func (r *Registry) Chat(ctx context.Context, messages []Message, opts ChatOptions, fn func(ChatChunk) error) error {
	return r.ChatWith(ctx, r.Model(), messages, opts, fn)
}

// ChatWith routes a chat through the explicit model, bypassing the registry's
// stored default.
func (r *Registry) ChatWith(ctx context.Context, model string, messages []Message, opts ChatOptions, fn func(ChatChunk) error) error {
	p, err := r.providerFor(ctx, model)
	if err != nil {
		return err
	}
	return p.Chat(ctx, model, messages, opts, fn)
}

// ProviderNameFor reports which provider serves the model ("ollama",
// "anthropic", …), or "" when none claims it.
func (r *Registry) ProviderNameFor(ctx context.Context, model string) string {
	p, err := r.providerFor(ctx, model)
	if err != nil {
		return ""
	}
	return p.Name()
}

func (r *Registry) Models(ctx context.Context) ([]string, error) {
	var all []string
	for _, listed := range r.probeAll(ctx) {
		all = append(all, <-listed...)
	}
	return all, nil
}

// probeAll starts every listing at once so a hung provider cannot spend a caller's deadline for the rest.
func (r *Registry) probeAll(ctx context.Context) []<-chan []string {
	results := make([]<-chan []string, len(r.providers))
	for i, p := range r.providers {
		listed := make(chan []string, 1)
		results[i] = listed
		go func() {
			models, _ := probeModels(ctx, p)
			listed <- models
		}()
	}
	return results
}

func probeModels(ctx context.Context, p Provider) ([]string, error) {
	probeCtx, cancel := context.WithTimeout(ctx, providerProbeTimeout)
	defer cancel()
	return p.Models(probeCtx)
}

func (r *Registry) Ping(ctx context.Context) bool {
	p, err := r.providerFor(ctx, r.Model())
	if err != nil {
		return false
	}
	return p.Ping(ctx)
}

func (r *Registry) providerFor(ctx context.Context, model string) (Provider, error) {
	if model == "" {
		return nil, fmt.Errorf("no model configured")
	}
	r.mu.RLock()
	cached := r.routeCache[model]
	r.mu.RUnlock()
	if cached != nil {
		return cached, nil
	}
	for i, listed := range r.probeAll(ctx) {
		if slices.Contains(<-listed, model) {
			p := r.providers[i]
			r.mu.Lock()
			r.routeCache[model] = p
			r.mu.Unlock()
			return p, nil
		}
	}
	return nil, fmt.Errorf("no provider found for model %q", model)
}
