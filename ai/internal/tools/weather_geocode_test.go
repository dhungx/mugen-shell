package tools

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestWeatherGeocodeOutageIsAnError(t *testing.T) {
	geo := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	t.Cleanup(geo.Close)
	api := testWeatherAPI("", geo.URL, geo.URL)

	out, err := api.get(context.Background(), map[string]any{"place": "Tokyo"})
	if err == nil || !strings.Contains(err.Error(), "place lookup") {
		t.Fatalf("err = %v, want a place lookup failure", err)
	}
	if strings.Contains(out, "could not find") {
		t.Errorf("out = %q, an outage is not a missing place", out)
	}
}
