package hypr

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

type client struct {
	Address      string `json:"address"`
	Class        string `json:"class"`
	InitialClass string `json:"initialClass"`
	Floating     bool   `json:"floating"`
}

var luaProviderRe = regexp.MustCompile(`(?m)^configProvider:\s*lua\s*$`)

// A Lua Hyprland config rejects the legacy dispatch string, so probe for it.
func usesLuaConfig(ctx context.Context) bool {
	if os.Getenv("HYPR_CONFIG_LUA") == "1" {
		return true
	}
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	out, err := exec.CommandContext(ctx, "hyprctl", "systeminfo").Output()
	if err != nil {
		return false
	}
	return luaProviderRe.Match(out)
}

func clients(ctx context.Context) ([]client, error) {
	// The caller's context carries no deadline, and a wedged hyprctl would hang the launch.
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	out, err := exec.CommandContext(ctx, "hyprctl", "clients", "-j").Output()
	if err != nil {
		return nil, fmt.Errorf("hyprctl clients: %w", err)
	}
	var parsed []client
	if err := json.Unmarshal(out, &parsed); err != nil {
		return nil, fmt.Errorf("hyprctl clients: %w", err)
	}
	return parsed, nil
}

// Focus raises the window matching desktopEntry. Reports whether one matched; (false, nil) means none is open.
func Focus(ctx context.Context, desktopEntry string) (bool, error) {
	term := strings.ToLower(strings.TrimSuffix(strings.ToLower(desktopEntry), ".desktop"))
	if term == "" {
		return false, nil
	}
	windows, err := clients(ctx)
	if err != nil {
		return false, err
	}

	for _, c := range windows {
		cls := strings.ToLower(c.Class)
		initial := strings.ToLower(c.InitialClass)

		if term == cls || term == initial ||
			// An empty class is a substring of everything, so it would swallow the match.
			(cls != "" && (strings.Contains(cls, term) || strings.Contains(term, cls))) ||
			(initial != "" && (strings.Contains(initial, term) || strings.Contains(term, initial))) {
			return true, focusWindow(ctx, c.Address, c.Floating)
		}
	}

	return false, nil
}

// FocusOrLaunch raises the window matching desktopEntry, or starts it when none
// is open. Reports whether a matching window was focused.
func FocusOrLaunch(ctx context.Context, desktopEntry string) (bool, error) {
	matched, err := Focus(ctx, desktopEntry)
	if matched || err != nil {
		return matched, err
	}
	return false, launch(desktopEntry)
}

func focusWindow(ctx context.Context, address string, floating bool) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	lua := usesLuaConfig(ctx)
	focus := []string{"dispatch", "focuswindow", "address:" + address}
	raise := []string{"dispatch", "alterzorder", "top,address:" + address}
	if lua {
		focus = []string{"dispatch", fmt.Sprintf("hl.dsp.focus({ window = \"address:%s\" })", address)}
		raise = []string{"dispatch", fmt.Sprintf("hl.dsp.window.alter_zorder({ mode = \"top\", window = \"address:%s\" })", address)}
	}
	if err := dispatch(ctx, address, focus); err != nil {
		return err
	}
	// Hyprland's focus dispatcher leaves a floating window's stacking order alone.
	if !floating {
		return nil
	}
	return dispatch(ctx, address, raise)
}

func dispatch(ctx context.Context, address string, args []string) error {
	out, err := exec.CommandContext(ctx, "hyprctl", args...).Output()
	if err != nil {
		return err
	}
	// hyprctl exits 0 even when the dispatch is rejected, so the reply is the only signal.
	if reply := strings.TrimSpace(string(out)); reply != "ok" {
		return fmt.Errorf("dispatch rejected for %s: %s", address, reply)
	}
	return nil
}

// Detached so the app outlives the short-lived process that asked for it.
func launch(desktopEntry string) error {
	cmd := exec.Command("gtk-launch", desktopEntry)
	cmd.SysProcAttr = detachedAttr()
	return cmd.Start()
}
