package crypto

import (
	sodium "github.com/GoKillers/libsodium-go/sodium"
	"sync"
)

var initOnce sync.Once

func InitSodiumForTest() {
	initOnce.Do(func() {
		sodium.Init()
	})
}