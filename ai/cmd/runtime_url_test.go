package cmd

import "testing"

func TestExpandURLEnvUnsetExpandsToEmpty(t *testing.T) {
	t.Setenv("MUGEN_TEST_SET", "tok")
	t.Setenv("MUGEN_TEST_EMPTY", "")
	got := expandURLEnv("srv", "http://h/${MUGEN_TEST_SET}/${MUGEN_TEST_EMPTY}/${MUGEN_TEST_UNSET_XYZ}?$select=1")
	if want := "http://h/tok//?$select=1"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}
