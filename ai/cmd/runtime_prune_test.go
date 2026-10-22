package cmd

import (
	"database/sql"
	"os"
	"path/filepath"
	"testing"

	"github.com/tmy7533018/mugen-ai/internal/store"
)

func TestOnlyServePrunesHistory(t *testing.T) {
	for _, tc := range []struct {
		prune bool
		want  int
	}{{false, 1}, {true, 0}} {
		sandboxRuntime(t)
		confPath := filepath.Join(os.Getenv("XDG_CONFIG_HOME"), "mugen-ai", "config.toml")
		f, err := os.OpenFile(confPath, os.O_APPEND|os.O_WRONLY, 0o600)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := f.WriteString("\n[history]\nretain_days = 1\n"); err != nil {
			t.Fatal(err)
		}
		f.Close()

		dbPath := filepath.Join(stateBaseDir(), "history.db")
		st, err := store.Open(dbPath)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := st.CreateConversation("old", "m", false); err != nil {
			t.Fatal(err)
		}
		st.Close()
		db, err := sql.Open("sqlite", dbPath)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := db.Exec("UPDATE conversations SET updated_at = 0"); err != nil {
			t.Fatal(err)
		}
		db.Close()

		rt, err := loadRuntimeContext("test-model", "", tc.prune)
		if err != nil {
			t.Fatal(err)
		}
		n, err := rt.Store.ConversationCount()
		if err != nil || n != tc.want {
			t.Errorf("prune=%v: %d conversations (%v), want %d", tc.prune, n, err, tc.want)
		}
		rt.MCP.Close()
		rt.Store.Close()
	}
}
