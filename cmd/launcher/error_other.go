//go:build !windows

package main

import (
    "fmt"
    "os"
)

func reportLaunchError(err error) { fmt.Fprintln(os.Stderr, err) }
