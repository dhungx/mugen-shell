package hypr

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func stubBin(t *testing.T, dir, name, body string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(dir, name), []byte("#!/bin/sh\n"+body+"\n"), 0o755); err != nil {
		t.Fatal(err)
	}
}

func hyprStubs(t *testing.T, clientsJSON string) (dispatchLog string) {
	t.Helper()
	dir := t.TempDir()
	dispatchLog = filepath.Join(dir, "dispatch.log")
	stubBin(t, dir, "hyprctl", `if [ "$1" = clients ]; then echo '`+clientsJSON+`'; else echo "$2" >> `+dispatchLog+`; echo ok; fi`)
	t.Setenv("PATH", dir+":/usr/bin:/bin")
	t.Setenv("HYPR_CONFIG_LUA", "1")
	return dispatchLog
}

func logLines(t *testing.T, path string) []string {
	t.Helper()
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		t.Fatal(err)
	}
	return strings.Split(strings.TrimSpace(string(b)), "\n")
}

func TestFocusOrLaunchDoesNotLaunchWhenHyprctlFails(t *testing.T) {
	dir := t.TempDir()
	marker := filepath.Join(dir, "launched")
	stubBin(t, dir, "hyprctl", "exit 1")
	stubBin(t, dir, "gtk-launch", "touch "+marker)
	t.Setenv("PATH", dir+":/usr/bin:/bin")
	t.Setenv("HYPR_CONFIG_LUA", "1")

	if _, err := FocusOrLaunch(context.Background(), "firefox"); err == nil {
		t.Error("expected an error when hyprctl clients fails")
	}
	time.Sleep(200 * time.Millisecond)
	if _, err := os.Stat(marker); err == nil {
		t.Error("launched a second copy although the window list was unknown")
	}
}

func TestFocusIgnoresABareDesktopSuffix(t *testing.T) {
	log := hyprStubs(t, `[{"address":"0xabc","class":"kitty","initialClass":"kitty"}]`)

	matched, err := Focus(context.Background(), ".desktop")
	if matched || err != nil {
		t.Errorf("Focus = (%v, %v), want (false, nil)", matched, err)
	}
	if lines := logLines(t, log); len(lines) != 0 {
		t.Errorf("dispatched %v", lines)
	}
}

func TestFocusRaisesOnlyFloatingWindows(t *testing.T) {
	for _, tc := range []struct {
		floating string
		want     []string
	}{
		{"true", []string{"hl.dsp.focus", "hl.dsp.window.alter_zorder"}},
		{"false", []string{"hl.dsp.focus"}},
	} {
		log := hyprStubs(t, `[{"address":"0xabc","class":"kitty","initialClass":"kitty","floating":`+tc.floating+`}]`)

		matched, err := Focus(context.Background(), "kitty")
		if !matched || err != nil {
			t.Fatalf("floating=%s: Focus = (%v, %v)", tc.floating, matched, err)
		}
		lines := logLines(t, log)
		if len(lines) != len(tc.want) {
			t.Fatalf("floating=%s: dispatched %v, want %d", tc.floating, lines, len(tc.want))
		}
		for i, w := range tc.want {
			if !strings.HasPrefix(lines[i], w) || !strings.Contains(lines[i], "address:0xabc") {
				t.Errorf("floating=%s: line %d = %q, want %s on 0xabc", tc.floating, i, lines[i], w)
			}
		}
	}
}
