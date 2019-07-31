package main

import (
	"github.com/coredns/coredns/coremain"
	clog "github.com/coredns/coredns/plugin/pkg/log"
	"github.com/mholt/caddy"
)

func init() {
	caddy.OnProcessExit = append(caddy.OnProcessExit, func() { clog.Infof("Tearing down") })
}

func main() {
	coremain.Run()
	// Unlikely to reach here, if we did it is because coremain exited and the signal was not trapped.
	clog.Errorf("Untrapped signal, tearing down")
}
