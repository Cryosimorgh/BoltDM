//go:build windows

package main

import (
    "fmt"
    "syscall"
    "unsafe"
)

var createBoltMutex = syscall.NewLazyDLL("kernel32.dll").NewProc("CreateMutexW")
var closeBoltHandle = syscall.NewLazyDLL("kernel32.dll").NewProc("CloseHandle")

// A user-session mutex prevents simultaneous starts from the login shortcut,
// the desktop launcher and manual double-clicks from opening the same state DB.
func acquireInstance() (bool, func(), error) {
    name, err := syscall.UTF16PtrFromString("Local\\BoltDM.Download.Service")
    if err != nil { return false, nil, err }
    handle, _, callErr := createBoltMutex.Call(0, 0, uintptr(unsafe.Pointer(name)))
    if handle == 0 { return false, nil, fmt.Errorf("CreateMutexW: %w", callErr) }
    if callErr == syscall.Errno(183) { // ERROR_ALREADY_EXISTS
        closeBoltHandle.Call(handle)
        return true, func(){}, nil
    }
    return false, func(){ closeBoltHandle.Call(handle) }, nil
}
