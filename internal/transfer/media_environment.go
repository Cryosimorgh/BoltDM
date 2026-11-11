package transfer

import (
	"os"
	"path/filepath"
	"strings"
)

// mediaSubprocessEnv avoids passing dead or untraversable Windows PATH entries
// to yt-dlp. Its postprocessors and runtime discovery can probe every PATH
// entry and fail on Windows reparse points (e.g. ERROR_UNTRUSTED_MOUNT_POINT).
// Keep the parent process and every non-PATH environment variable unchanged.
func mediaSubprocessEnv(env []string, goos string) []string {
	if goos != "windows" {
		return env
	}
	result := make([]string, len(env))
	copy(result, env)
	for i, assignment := range result {
		eq := strings.IndexByte(assignment, '=')
		if eq <= 0 || !strings.EqualFold(assignment[:eq], "PATH") {
			continue
		}
		parts := strings.Split(assignment[eq+1:], ";")
		keep := make([]string, 0, len(parts))
		for _, part := range parts {
			dir := strings.Trim(strings.TrimSpace(part), "\"")
			if dir == "" {
				continue
			}
			st, err := os.Stat(dir)
			if err != nil || !st.IsDir() {
				continue
			}
			// Checking the directory itself is insufficient for some junctions.
			// Probe a child path: missing is fine, traversal errors are not.
			probe := filepath.Join(dir, "__boltdm_path_probe__.exe")
			_, err = os.Stat(probe)
			if err != nil && !os.IsNotExist(err) {
				continue
			}
			keep = append(keep, part)
		}
		result[i] = assignment[:eq+1] + strings.Join(keep, ";")
	}
	return result
}
