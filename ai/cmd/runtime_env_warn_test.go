package cmd

import (
	"io"
	"os"
	"strings"
	"testing"

	"github.com/tmy7533018/mugen-ai/internal/config"
)

func stderrOf(t *testing.T, f func()) string {
	t.Helper()
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	old := os.Stderr
	os.Stderr = w
	f()
	os.Stderr = old
	w.Close()
	out, _ := io.ReadAll(r)
	return string(out)
}

func TestMCPServerEnvWarnsOnAnUnsetRef(t *testing.T) {
	t.Setenv("MUGEN_TEST_EMPTY", "")
	got := stderrOf(t, func() {
		mcpServerConfigs(config.MCP{Servers: map[string]config.MCPServer{
			"zap": {Command: "x", Env: map[string]string{
				"TOKEN": "${MUGEN_TEST_UNSET_XYZ}",
				"EMPTY": "${MUGEN_TEST_EMPTY}",
			}},
		}}, nil)
	})
	if want := "mcp[zap]: env TOKEN references unset ${MUGEN_TEST_UNSET_XYZ}"; !strings.Contains(got, want) {
		t.Errorf("stderr = %q, want it to contain %q", got, want)
	}
	if strings.Contains(got, "MUGEN_TEST_EMPTY") {
		t.Errorf("stderr = %q, a set-but-empty variable is not a typo", got)
	}
}

func TestDisabledMCPServerEnvIsNotExpanded(t *testing.T) {
	var got map[string]string
	out := stderrOf(t, func() {
		got = mcpServerConfigs(config.MCP{Servers: map[string]config.MCPServer{
			"off": {Command: "x", Env: map[string]string{"TOKEN": "${MUGEN_TEST_UNSET_XYZ}"}, Disabled: true},
		}}, nil)["off"].Env
	})
	if out != "" {
		t.Errorf("stderr = %q, want no warning for a disabled server", out)
	}
	if got["TOKEN"] != "${MUGEN_TEST_UNSET_XYZ}" {
		t.Errorf("env[TOKEN] = %q, want it left unexpanded", got["TOKEN"])
	}
}
