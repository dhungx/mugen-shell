package tools

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"github.com/tmy7533018/mugen-ai/internal/apps"
)

func TestAppLaunchLeavesTheCallersArgsAlone(t *testing.T) {
	data := t.TempDir()
	if err := os.MkdirAll(filepath.Join(data, "applications"), 0o755); err != nil {
		t.Fatal(err)
	}
	desktop := "[Desktop Entry]\nType=Application\nName=Thing\nExec=/opt/thing/bin/thing\n"
	if err := os.WriteFile(filepath.Join(data, "applications", "thing.desktop"), []byte(desktop), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("XDG_DATA_HOME", data)
	t.Setenv("XDG_DATA_DIRS", t.TempDir())

	r, fr, _ := newTestRegistry(t, []string{"thing"}, nil)
	r.apps = apps.Load()
	args := map[string]any{"cmd": "thing"}
	if _, err := r.Call(context.Background(), "app_launch", args); err != nil {
		t.Fatal(err)
	}

	if args["cmd"] != "thing" {
		t.Errorf("args[cmd] = %v, want it untouched", args["cmd"])
	}
	if len(fr.args) == 0 || fr.args[len(fr.args)-1] != "/opt/thing/bin/thing" {
		t.Errorf("run args = %v, want the resolved Exec last", fr.args)
	}
}
