package tools

import (
	"context"
	"testing"
)

func TestOneLineDropsFormatCharacters(t *testing.T) {
	r := func(cp ...rune) string { return string(cp) }
	zwj := r(0x200d)
	for in, want := range map[string]string{
		"a" + r(0x202e, 0x2066, 0x2067, 0x2068, 0x2069) + "b": "ab",
		"a" + r(0x200b) + "b" + r(0xfeff) + "c":               "abc",
		"a" + r(0xe0041) + "b" + r(0x1b) + "c":                "abc",
		"a\nb\tc":                                             "a b c",
		r(0x1f469) + zwj + r(0x1f4bb):                         r(0x1f469) + zwj + r(0x1f4bb),
		r(0x0915, 0x094d) + zwj + r(0x0937):                   r(0x0915, 0x094d) + zwj + r(0x0937),
	} {
		if got := oneLine(in); got != want {
			t.Errorf("oneLine(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestMemorySaveStripsTagCharacters(t *testing.T) {
	r, st := newMemoryRegistry(t, nil)
	content := "likes" + string(rune(0xe0041)) + " tea"
	if _, err := r.Call(context.Background(), "memory_save", map[string]any{"content": content}); err != nil {
		t.Fatalf("save: %v", err)
	}
	mems, err := st.ListMemories()
	if err != nil || len(mems) != 1 || mems[0].Content != "likes tea" {
		t.Fatalf("stored %+v (%v)", mems, err)
	}
}
