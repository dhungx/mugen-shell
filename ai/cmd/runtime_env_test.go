package cmd

import (
	"testing"

	"github.com/tmy7533018/mugen-ai/internal/config"
)

func TestMCPServerEnvExpandsOnlyBracedRefs(t *testing.T) {
	t.Setenv("ZAP_SECRET", "s3cr3t")
	got := mcpServerConfigs(config.MCP{Servers: map[string]config.MCPServer{
		"zap": {Command: "x", Env: map[string]string{
			"A": "${ZAP_SECRET}",
			"B": "pa$$word",
			"C": "abc$def",
			"D": "$ZAP_SECRET",
			"E": "${UNSET_FOR_TEST_XYZ}",
		}},
	}}, nil)["zap"].Env

	want := map[string]string{"A": "s3cr3t", "B": "pa$$word", "C": "abc$def", "D": "$ZAP_SECRET", "E": ""}
	for k, v := range want {
		if got[k] != v {
			t.Errorf("env[%s] = %q, want %q", k, got[k], v)
		}
	}
}
