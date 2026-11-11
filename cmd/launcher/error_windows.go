//go:build windows

package main

import (
    "syscall"
    "unsafe"
)

func reportLaunchError(err error) {
    title, _ := syscall.UTF16PtrFromString("BoltDM launcher")
    message, _ := syscall.UTF16PtrFromString(err.Error())
    proc := syscall.NewLazyDLL("user32.dll").NewProc("MessageBoxW")
    proc.Call(0, uintptr(unsafe.Pointer(message)), uintptr(unsafe.Pointer(title)), 0x10)
}
