package hypr

import "testing"

func TestIsRelevantKeepsOccupancyEventsAndDropsTitleChurn(t *testing.T) {
	cases := map[string]bool{
		"openwindow": true, "closewindow": true, "movewindow": true, "movewindowv2": true,
		"workspace": true, "workspacev2": true, "createworkspacev2": true, "destroyworkspacev2": true,
		"moveworkspacev2": true, "focusedmon": true, "focusedmonv2": true, "monitoraddedv2": true,
		"windowtitle": false, "windowtitlev2": false, "activewindow": false, "activewindowv2": false,
		"activelayout": false, "openlayer": false, "changefloatingmode": false,
	}
	for name, want := range cases {
		if got := isRelevant(name); got != want {
			t.Errorf("isRelevant(%q) = %v, want %v", name, got, want)
		}
	}
}
