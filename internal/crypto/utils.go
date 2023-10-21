package crypto

func memZero(b []byte) {
	for i := range b {
		b[i] = 0
	}
}
