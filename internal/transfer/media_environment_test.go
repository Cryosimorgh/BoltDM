package transfer

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMediaSubprocessEnvPrunesBrokenWindowsPath(t *testing.T) {
	valid := t.TempDir()
	missing := filepath.Join(t.TempDir(), "invalid")
	input := []string{"LOCALAPPDATA=keep", "Path=" + valid + ";" + missing + ";;" + valid, "USERPROFILE=test"}
	got := mediaSubprocessEnv(input, "windows")
	want := "Path=" + valid + ";" + valid
	if got[1] != want {
		t.Fatalf("PATH = %q, want %q", got[1], want)
	}
	if got[0] != input[0] || got[2] != input[2] {
		t.Fatalf("non-PATH environment modified: %v", got)
	}
	if input[1] == got[1] {
		t.Fatal("PATH was not filtered")
	}
}

func TestMediaSubprocessEnvDoesNotTouchNonWindows(t *testing.T) {
	input := []string{"PATH=/does/not/exist", "FOO=bar"}
	got := mediaSubprocessEnv(input, "linux")
	if strings.Join(got, ";") != strings.Join(input, ";") {
		t.Fatalf("Linux PATH changed: %v", got)
	}
}

func TestMediaSubprocessEnvKeepsValidChildTraversal(t *testing.T) {
	valid := t.TempDir()
	if err := os.WriteFile(filepath.Join(valid, "ffmpeg.exe"), []byte("test"), 0600); err != nil {
		t.Fatal(err)
	}
	env := mediaSubprocessEnv([]string{"PATH=" + valid}, "windows")
	if env[0] != "PATH="+valid {
		t.Fatalf("valid directory removed from PATH: %q", env[0])
	}
}
