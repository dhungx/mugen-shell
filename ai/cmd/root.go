package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "mugen-ai",
	Short: "AI assistant backend for mugen-shell",
	Long:  "mugen-ai is the assistant backend for mugen-shell: cloud or local models, desktop tools and MCP, served over a unix socket.",
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
