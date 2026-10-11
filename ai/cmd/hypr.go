package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/tmy7533018/mugen-ai/internal/hypr"
)

var hyprCmd = &cobra.Command{
	Use:   "hypr",
	Short: "Hyprland helpers the shell shells out to",
}

var hyprMonitorCmd = &cobra.Command{
	Use:   "monitor",
	Short: "Stream workspace and window events, one per line, until the socket closes",
	Args:  cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		return hypr.Monitor(os.Stdout)
	},
	SilenceUsage: true,
}

// Only a window that was found but could not be raised counts as failure.
var hyprFocusCmd = &cobra.Command{
	Use:   "focus-or-launch <desktop-entry>",
	Short: "Raise the window for a desktop entry, or launch it when none is open",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		focus := hypr.FocusOrLaunch
		if noLaunch, _ := cmd.Flags().GetBool("no-launch"); noLaunch {
			focus = hypr.Focus
		}
		matched, err := focus(cmd.Context(), args[0])
		if err != nil {
			fmt.Fprintln(os.Stderr, "hypr focus-or-launch:", err)
			if matched {
				os.Exit(1)
			}
		}
		return nil
	},
	SilenceUsage: true,
}

func init() {
	hyprFocusCmd.Flags().Bool("no-launch", false, "only raise a matching window, never start the app")
	hyprCmd.AddCommand(hyprMonitorCmd)
	hyprCmd.AddCommand(hyprFocusCmd)
	rootCmd.AddCommand(hyprCmd)
}
