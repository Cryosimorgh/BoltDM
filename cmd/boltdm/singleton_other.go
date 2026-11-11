//go:build !windows

package main

func acquireInstance() (bool, func(), error) {
    return false, func(){}, nil
}
