// Package srp is port of node-srp to Go.
//
// To use SRP, first decide on they parameters you will use. Both client and server must
// use the same set.
//
//	params := srp.GetParams(4096)
//
// From the client... generate a new secret key, initialize the client, and compute A.
// Once you have A, you can send A to the server.
//
//	secret1 := srp.GenKey()
//	client := NewClient(params, salt, identity, secret, a)
//	srpA := client.computeA()
//
//	sendToServer(srpA)
//
// From the server... generate another secret key, initialize the server, and compute B.
// Once you have B, you can send B to the client.
//
//	secret2 := srp.GenKey()
//	server := NewServer(params, verifier, secret2)
//	srpB := client.computeB()
//
//	sendToClient(srpB)
//
// Once the client received B from the server, it can compute M1 based on A and B.
// Once you have M1, send M1 to the server.
//
//	client.setB(srpB)
//	srpM1 := client.ComputeM1()
//	sendM1ToServer(srpM1)
//
// Once the server receives M1, it can verify that it is correct. If checkM1() returns
// an error, authentication failed. If it succeeds it should be sent to the client.
//
//	srpM2, err := server.checkM1(srpM1)
//
// Once the client receives M2, it can verify that it is correct, and know that authentication
// was successful.
//
//	err = client.CheckM2(serverM2)
//
// Now that both client and server have completed a successful authentication, they can
// both compute K independently. K can now be used as either a key to encrypt communication
// or as a session ID.
//
//	clientK := client.ComputeK()
//	serverK := server.ComputeK()
package srp

import (
	"crypto/rand"
	"github.com/sirupsen/logrus"
	"io"
	"math/big"
)

func GenKey() []byte {
	bytes := make([]byte, 32)
	_, err := io.ReadFull(rand.Reader, bytes)
	if err != nil {
		panic("Random source is broken!")
	}

	return bytes
}

func getK(params *SRPParams, S []byte) []byte {
	hashK := params.Hash.New()
	logrus.Infof("getK: length of S %d", len(S))
	hashK.Write(S)
	return hashToBytes(hashK)
}

func getu(params *SRPParams, A, B *big.Int) *big.Int {
	hashU := params.Hash.New()
	hashU.Write(padToN(A, params))
	hashU.Write(padToN(B, params))

	return hashToInt(hashU)
}

func getM1(params *SRPParams, A, B, S []byte) []byte {
	hashM1 := params.Hash.New()
	logrus.Infof("getM1: length of A %d, B %d, S %d", len(A), len(B), len(S))
	hashM1.Write(A)
	hashM1.Write(B)
	hashM1.Write(S)
	return hashToBytes(hashM1)
}

func getM2(params *SRPParams, A, M, K []byte) []byte {
	hashM1 := params.Hash.New()
	logrus.Infof("getM2: length of A %d, M %d, K %d", len(A), len(M), len(K))
	hashM1.Write(A)
	hashM1.Write(M)
	hashM1.Write(K)
	return hashToBytes(hashM1)
}

func getMultiplier(params *SRPParams) *big.Int {
	hashK := params.Hash.New()
	hashK.Write(padToN(params.N, params))
	hashK.Write(padToN(params.G, params))

	return hashToInt(hashK)
}
