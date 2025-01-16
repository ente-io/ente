package srp

import (
	"bytes"
	"errors"
	"fmt"
	"math/big"
)

type SRPServer struct {
	Params   *SRPParams
	Verifier *big.Int
	Secret2  *big.Int
	B        *big.Int
	M1       []byte
	M2       []byte
	K        []byte
	u        *big.Int
	s        *big.Int
}

func NewServer(params *SRPParams, Vb []byte, S2b []byte) *SRPServer {
	multiplier := getMultiplier(params)
	V := intFromBytes(Vb)
	secret2 := intFromBytes(S2b)

	Bb := getB(params, multiplier, V, secret2)
	B := intFromBytes(Bb)

	return &SRPServer{
		Params:   params,
		Secret2:  secret2,
		Verifier: V,
		B:        B,
	}
}

func (s *SRPServer) ComputeB() []byte {
	return padToN(s.B, s.Params)
}

func (s *SRPServer) SetA(A []byte) {
	if len(A) != 512 {
		panic("invalid client-supplied 'A', must be 1..N-1")
	}
	AInt := intFromBytes(A)
	U := getu(s.Params, AInt, s.B)
	S := serverGetS(s.Params, s.Verifier, AInt, s.Secret2, U)

	s.K = getK(s.Params, S)
	s.M1 = getM1(s.Params, A, intToBytes(s.B), S)
	s.M2 = getM2(s.Params, A, s.M1, s.K)

	s.u = U               // only for tests
	s.s = intFromBytes(S) // only for tests
}

func (s *SRPServer) CheckM1(M1 []byte) ([]byte, error) {
	if len(s.M1) != len(M1) {
		return nil, fmt.Errorf("client m1 length (%d) is different from server m1 length %d", len(M1), len(s.M1))
	}
	if !bytes.Equal(s.M1, M1) {
		return nil, errors.New("Client did not use the same password")
	} else {
		return s.M2, nil
	}
}

func (s *SRPServer) ComputeK() []byte {
	return s.K
}

// Helpers

func serverGetS(params *SRPParams, V, A, S2, U *big.Int) []byte {
	ALessThan0 := A.Cmp(big.NewInt(0)) <= 0
	NLessThanA := params.N.Cmp(A) <= 0
	if ALessThan0 || NLessThanA {
		panic("invalid client-supplied 'A', must be 1..N-1")
	}

	result1 := new(big.Int)
	result1.Exp(V, U, params.N)

	result2 := new(big.Int)
	result2.Mul(A, result1)

	result3 := new(big.Int)
	result3.Exp(result2, S2, params.N)

	result4 := new(big.Int)
	result4.Mod(result3, params.N)

	return padToN(result4, params)
}

func getB(params *SRPParams, multiplier, V, b *big.Int) []byte {
	gModPowB := new(big.Int)
	gModPowB.Exp(params.G, b, params.N)

	kMulV := new(big.Int)
	kMulV.Mul(multiplier, V)

	leftSide := new(big.Int)
	leftSide.Add(kMulV, gModPowB)

	final := new(big.Int)
	final.Mod(leftSide, params.N)

	return padToN(final, params)
}
