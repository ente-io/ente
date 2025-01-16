package srp

import (
	"bytes"
	"errors"
	"math/big"
)

type SRPClient struct {
	Params     *SRPParams
	Secret1    *big.Int
	Multiplier *big.Int
	A          *big.Int
	X          *big.Int
	M1         []byte
	M2         []byte
	K          []byte
	u          *big.Int
	s          *big.Int
}

func NewClient(params *SRPParams, salt, identity, password, secret1 []byte) *SRPClient {
	multiplier := getMultiplier(params)
	secret1Int := intFromBytes(secret1)
	Ab := getA(params, secret1Int)
	A := intFromBytes(Ab)
	x := getx(params, salt, identity, password)

	return &SRPClient{
		Params:     params,
		Multiplier: multiplier,
		Secret1:    secret1Int,
		A:          A,
		X:          x,
	}
}

func (c *SRPClient) ComputeA() []byte {
	return padToN(c.A, c.Params)
}

// ComputeVerifier returns a verifier that is calculated as described in
// Section 3 of [SRP-RFC]
func ComputeVerifier(params *SRPParams, salt, identity, password []byte) []byte {
	x := getx(params, salt, identity, password)
	vNum := new(big.Int)
	vNum.Exp(params.G, x, params.N)

	return padToN(vNum, params)
}

func (c *SRPClient) SetB(Bb []byte) {
	B := intFromBytes(Bb)
	u := getu(c.Params, c.A, B)
	S := clientGetS(c.Params, c.Multiplier, c.X, c.Secret1, B, u)

	c.K = getK(c.Params, S)
	c.M1 = getM1(c.Params, padToN(c.A, c.Params), Bb, S)
	c.M2 = getM2(c.Params, padToN(c.A, c.Params), c.M1, c.K)

	c.u = u               // Only for tests
	c.s = intFromBytes(S) // Only for tests
}

func (c *SRPClient) ComputeM1() []byte {
	if c.M1 == nil {
		panic("Incomplete protocol")
	}

	return c.M1
}

func (c *SRPClient) ComputeK() []byte {
	return c.K
}

func (c *SRPClient) CheckM2(M2 []byte) error {
	if !bytes.Equal(c.M2, M2) {
		return errors.New("M2 didn't check")
	} else {
		return nil
	}
}

func getA(params *SRPParams, a *big.Int) []byte {
	ANum := new(big.Int)
	ANum.Exp(params.G, a, params.N)
	return padToN(ANum, params)
}

func clientGetS(params *SRPParams, k, x, a, B, u *big.Int) []byte {
	BLessThan0 := B.Cmp(big.NewInt(0)) <= 0
	NLessThanB := params.N.Cmp(B) <= 0
	if BLessThan0 || NLessThanB {
		panic("invalid server-supplied 'B', must be 1..N-1")
	}

	result1 := new(big.Int)
	result1.Exp(params.G, x, params.N)

	result2 := new(big.Int)
	result2.Mul(k, result1)

	result3 := new(big.Int)
	result3.Sub(B, result2)

	result4 := new(big.Int)
	result4.Mul(u, x)

	result5 := new(big.Int)
	result5.Add(a, result4)

	result6 := new(big.Int)
	result6.Exp(result3, result5, params.N)

	result7 := new(big.Int)
	result7.Mod(result6, params.N)

	return padToN(result7, params)
}

func getx(params *SRPParams, salt, I, P []byte) *big.Int {
	var ipBytes []byte
	ipBytes = append(ipBytes, I...)
	ipBytes = append(ipBytes, []byte(":")...)
	ipBytes = append(ipBytes, P...)

	hashIP := params.Hash.New()
	hashIP.Write(ipBytes)

	hashX := params.Hash.New()
	hashX.Write(salt)
	hashX.Write(hashToBytes(hashIP))

	return hashToInt(hashX)
}
