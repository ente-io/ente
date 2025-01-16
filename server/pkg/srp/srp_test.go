package srp

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"math/big"
	"testing"
)

var salt = []byte("salty")
var identity = []byte("alice")
var password = []byte("password123")

func getAAndB() ([]byte, []byte) {
	a := GenKey()
	b := GenKey()
	return a, b
}

func getVerifier() []byte {
	return bytesFromHexString(`
		F0E47F50 F5DEAD8D B8D93A27 9E3B62D6 FF50854B 31FBD347 4A886BEF
		91626171 7E84DD4F B8B4D27F EAA5146D B7B1CBBC 274FDF96 A132B502
		9C2CD725 27427A9B 9809D5A4 D0182529 28B4FC34 3BC17CE6 3C1859D5
		806F5466 014FC361 002D8890 AEB4D631 6FF37331 FC2761BE 0144C91C
		DD8E00ED 0138C0CE 51534D1B 9A9BA629 D7BE34D2 742DD409 7DAABC9E
		CB7AAAD8 9E53C342 B038F1D2 ADAE1F24 10B7884A 3E9A124C 357E421B
		CCD45244 67E19226 60E0A446 0C5F7C38 C0877B65 F6E32F28 296282A9
		3FC11BBA BB7BB69B F1B3F939 1991D8A8 6DD05E15 000B7E38 BA38A536
		BB0BF59C 808EC25E 791B8944 719488B8 087DF8BF D7FF2082 2997A53F
		6C86F3D4 5D004476 D6303301 376BB25A 9F94B552 CCE5ED40 DE5DD7DA
		8027D754 FA5F6673 8C7E3FC4 EF3E20D6 25DF62CB E6E7ADFC 21E47880
		D8A6ADA3 7E60370F D4D8FC82 672A90C2 9F2E72F3 5652649D 68348DE6
		F36D0E43 5C8BD42D D00155D3 5D501BEC C0661B43 E04CDB2D A84CE92B
		8BF49935 D73D75EF CBD1176D 7BBCCC3C C4D4B5FE FCC02D47 8614EE16
		81D2FF3C 711A61A7 686EB852 AE06FB82 27BE21FB 8802719B 1271BA1C
		02B13BBF 0A2C2E45 9D9BEDCC 8D1269F6 A785CB45 63AA791B 38FB0382
		69F63F58 F47E9051 49954978 9269CC7B 8EC7026F C34BA732 89C4AF82
		9D5A532E 723967CE 9B6C023E F0FD0CFE 37F51F10 F19463B6 534159A0
		9DDD2F51 F3B30033
	`)
}

func TestCreateVerifier(t *testing.T) {
	verifier := ComputeVerifier(GetParams(4096), salt, identity, password)
	expected := getVerifier()
	assert.Equal(t, expected, verifier, "Verifier did not match")
}

func TestUseAAndB(t *testing.T) {
	for i := 0; i < 1000; i++ {

		t.Run(fmt.Sprintf("Run%d", i), func(t *testing.T) {
			//params := GetParams(4096)

			clientSecretSmallA := GenKey()
			serverSecret := GenKey()
			srpParams := GetParams(4096)
			//a, serverSecret := getAAndB()

			// Create client
			client := NewClient(srpParams, salt, identity, password, clientSecretSmallA)

			// Client produces A
			A := client.ComputeA()
			srpVerifier := ComputeVerifier(srpParams, salt, identity, password)

			// Create server
			server := NewServer(srpParams, srpVerifier, serverSecret)

			// Server accepts A
			server.SetA(A)

			// Server produces B
			B := server.ComputeB()

			// Client accepts B
			client.SetB(B)

			// Client produces M1 now
			M1 := client.ComputeM1()

			// Server likes client's M1
			serverM2, err := server.CheckM1(M1)
			assert.NoError(t, err, "Server should have liked M1")

			// Client and server agree on K
			clientK := client.ComputeK()
			serverK := server.ComputeK()
			assert.Equal(t, clientK, serverK, "K's should match")

			err = client.CheckM2(serverM2)
			assert.NoError(t, err, "M2 should have been valid")
		})
	}
}

func TestServerRejectsWrongM1(t *testing.T) {
	a, b := getAAndB()
	params := GetParams(4096)
	badClient := NewClient(params, salt, identity, []byte("Bad"), a)
	server := NewServer(params, getVerifier(), b)
	badClient.SetB(server.ComputeB())
	_, err := server.CheckM1(badClient.ComputeM1())
	assert.EqualError(t, err, "Client did not use the same password", "M1 check should have failed")
}

func TestServerRejectsBadA(t *testing.T) {
	// client's "A" must be 1..N-1 . Reject 0 and N and N+1. We should
	// reject 2*N too, but our Buffer-length checks reject it before the
	// number itself is examined.

	_, b := getAAndB()
	params := GetParams(4096)
	server := NewServer(params, getVerifier(), b)

	assert.Panics(t, func() {
		server.SetA(intToBytes(big.NewInt(0)))
	}, "Server should have paniced")

	assert.Panics(t, func() {
		server.SetA(intToBytes(params.N))
	}, "Server should have paniced")

	assert.Panics(t, func() {
		NPlus1 := new(big.Int)
		NPlus1.Add(params.N, big.NewInt(1))
		server.SetA(intToBytes(NPlus1))
	}, "Server should have paniced")
}

func TestClientRejectsBadB(t *testing.T) {
	// server's "B" must be 1..N-1 . Reject 0 and N and N+1
	a, _ := getAAndB()
	params := GetParams(4096)
	client := NewClient(params, salt, identity, password, a)

	assert.Panics(t, func() {
		client.SetB(intToBytes(big.NewInt(0)))
	}, "Client should have paniced")

	assert.Panics(t, func() {
		client.SetB(intToBytes(params.N))
	}, "Client should have paniced")

	assert.Panics(t, func() {
		NPlus1 := new(big.Int)
		NPlus1.Add(params.N, big.NewInt(1))
		client.SetB(intToBytes(NPlus1))
	}, "Client should have paniced")
}

func TestClientRejectsBadM2(t *testing.T) {
	a, b := getAAndB()
	params := GetParams(4096)
	client := NewClient(params, salt, identity, password, a)

	// Client produces A
	A := client.ComputeA()

	// Create server
	server := NewServer(params, getVerifier(), b)

	// Server produced B
	B := server.ComputeB()

	// Server accepts A
	server.SetA(A)

	// Client accepts B
	client.SetB(B)

	// Client produces M1 now
	M1 := client.ComputeM1()

	// Server likes client's M1
	server.CheckM1(M1)

	// We tamper with server's M2
	tamperedM2 := append(server.M2, 'a')

	// Client and server agree on K
	clientK := client.ComputeK()
	serverK := server.ComputeK()
	assert.Equal(t, clientK, serverK, "Ks should match")

	err := client.CheckM2(tamperedM2)
	assert.EqualError(t, err, "M2 didn't check", "Client should reject M2")
}

func TestRFC5054(t *testing.T) {
	params := GetParams(1024)
	I := []byte("alice")
	P := []byte("password123")
	s := bytesFromHexString("beb25379d1a8581eb5a727673a2441ee")
	kExpected := bytesFromHexString("7556aa045aef2cdd07abaf0f665c3e818913186f")
	xExpected := bytesFromHexString("94b7555aabe9127cc58ccf4993db6cf84d16c124")
	vExpected := bytesFromHexString(`
		7e273de8 696ffc4f 4e337d05 b4b375be b0dde156 9e8fa00a 9886d812
		9bada1f1 822223ca 1a605b53 0e379ba4 729fdc59 f105b478 7e5186f5
		c671085a 1447b52a 48cf1970 b4fb6f84 00bbf4ce bfbb1681 52e08ab5
		ea53d15c 1aff87b2 b9da6e04 e058ad51 cc72bfc9 033b564e 26480d78
		e955a5e2 9e7ab245 db2be315 e2099afb`)
	a := bytesFromHexString("60975527035cf2ad1989806f0407210bc81edc04e2762a56afd529ddda2d4393")
	b := bytesFromHexString("e487cb59d31ac550471e81f00f6928e01dda08e974a004f49e61f5d105284d20")
	AExpected := bytesFromHexString(`
		61d5e490 f6f1b795 47b0704c 436f523d d0e560f0 c64115bb 72557ec4
                4352e890 3211c046 92272d8b 2d1a5358 a2cf1b6e 0bfcf99f 921530ec
                8e393561 79eae45e 42ba92ae aced8251 71e1e8b9 af6d9c03 e1327f44
                be087ef0 6530e69f 66615261 eef54073 ca11cf58 58f0edfd fe15efea
                b349ef5d 76988a36 72fac47b 0769447b`)
	BExpected := bytesFromHexString(`
		bd0c6151 2c692c0c b6d041fa 01bb152d 4916a1e7 7af46ae1 05393011
                baf38964 dc46a067 0dd125b9 5a981652 236f99d9 b681cbf8 7837ec99
                6c6da044 53728610 d0c6ddb5 8b318885 d7d82c7f 8deb75ce 7bd4fbaa
                37089e6f 9c6059f3 88838e7a 00030b33 1eb76840 910440b1 b27aaeae
                eb4012b7 d7665238 a8e3fb00 4b117b58`)
	uExpected := bytesFromHexString("ce38b9593487da98554ed47d70a7ae5f462ef019")
	SExpected := bytesFromHexString(`
		b0dc82ba bcf30674 ae450c02 87745e79 90a3381f 63b387aa f271a10d
                233861e3 59b48220 f7c4693c 9ae12b0a 6f67809f 0876e2d0 13800d6c
                41bb59b6 d5979b5c 00a172b4 a2a5903a 0bdcaf8a 709585eb 2afafa8f
                3499b200 210dcc1f 10eb3394 3cd67fc8 8a2f39a4 be5bec4e c0a3212d
                c346d7e4 74b29ede 8a469ffe ca686e5a`)

	verifier := ComputeVerifier(params, s, I, P)
	client := NewClient(params, s, I, P, a)

	// X
	assert.Equal(t, xExpected, intToBytes(client.X), "x should match")

	// V
	assert.Equal(t, vExpected, verifier, "Verifier should match")

	// k
	assert.Equal(t, kExpected, intToBytes(client.Multiplier), "k should match")

	// A
	assert.Equal(t, AExpected, client.ComputeA(), "A should match")

	// B
	server := NewServer(params, verifier, b)
	assert.Equal(t, BExpected, server.ComputeB(), "B should match")

	// u and S client
	client.SetB(BExpected)
	assert.Equal(t, uExpected, intToBytes(client.u), "u should match")
	assert.Equal(t, SExpected, intToBytes(client.s), "S should match")

	// S server
	server.SetA(AExpected)
	assert.Equal(t, SExpected, intToBytes(server.s), "S should match")
}
