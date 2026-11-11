// BoltDM-Launcher is the user-facing entry point. It starts the existing
// download service, leaves it running after the browser closes, and opens UI
// only for interactive launches. It must live beside BoltDM.exe.
package main

import (
    "errors"
    "flag"
    "fmt"
    "net/http"
    "os"
    "os/exec"
    "path/filepath"
    "runtime"
    "time"
)

const dashboard = "http://127.0.0.1:17654"
const key = "b7a9f4e6b8634a9bbf95c7a84c2d3e71"

func main() {
    background := flag.Bool("background", false, "start BoltDM in the tray without opening the dashboard")
    flag.Parse()
    if err := launch(*background); err != nil {
        reportLaunchError(err)
        os.Exit(1)
    }
}

func launch(background bool) error {
    if isRunning() {
        if !background { return openDashboard() }
        return nil
    }
    executable, err := os.Executable()
    if err != nil { return err }
    engine := "boltdm"
    if runtime.GOOS == "windows" { engine = "BoltDM.exe" }
    engine = filepath.Join(filepath.Dir(executable), engine)
    if _, err := os.Stat(engine); err != nil {
        return fmt.Errorf("download service missing beside launcher: %w", err)
    }
    cmd := exec.Command(engine, "--background")
    if err := cmd.Start(); err != nil { return fmt.Errorf("start BoltDM: %w", err) }
    // A second launcher may race the first; either way, only the service's
    // authenticated local API confirms the download engine is ready.
    for i := 0; i < 40; i++ {
        if isRunning() {
            if !background { return openDashboard() }
            return nil
        }
        time.Sleep(125 * time.Millisecond)
    }
    return errors.New("BoltDM did not become ready; inspect ~/.boltdm/boltdm.log")
}

func isRunning() bool {
    client := http.Client{Timeout: 250 * time.Millisecond}
    req, err := http.NewRequest(http.MethodGet, dashboard + "/api/v1/tasks", nil)
    if err != nil { return false }
    req.Header.Set("X-BoltDM-Key", key)
    res, err := client.Do(req)
    if err != nil { return false }
    defer res.Body.Close()
    return res.StatusCode == http.StatusOK
}

func openDashboard() error {
    switch runtime.GOOS {
    case "windows":
        return exec.Command("rundll32", "url.dll,FileProtocolHandler", dashboard).Start()
    case "darwin":
        return exec.Command("open", dashboard).Start()
    default:
        return exec.Command("xdg-open", dashboard).Start()
    }
}
