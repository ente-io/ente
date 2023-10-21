package crypto

func memZero(b []byte) {
	for i := range b {
		b[i] = 0
	}
}

func xorBuf(out, in []byte) {
	for i := range out {
		out[i] ^= in[i]
	}
}

func bufInc(n []byte) {
	c := 1

	for i := range n {
		c += int(n[i])
		n[i] = byte(c)
		c >>= 8
	}
}
