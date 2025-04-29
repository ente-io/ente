package crypto

import (
	"bytes"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"fmt"
	"golang.org/x/crypto/chacha20"
	"golang.org/x/crypto/chacha20poly1305"
	"golang.org/x/crypto/poly1305"
)

// public constants
const (
	//TagMessage the most common tag, that doesn't add any information about the nature of the message.
	TagMessage = 0
	// TagPush indicates that the message marks the end of a set of messages,
	// but not the end of the stream. For example, a huge JSON string sent as multiple chunks can use this tag to indicate to the application that the string is complete and that it can be decoded. But the stream itself is not closed, and more data may follow.
	TagPush = 0x01
	// TagRekey "forget" the key used to encrypt this message and the previous ones, and derive a new secret key.
	TagRekey = 0x02
	// TagFinal indicates that the message marks the end of the stream, and erases the secret key used to encrypt the previous sequence.
	TagFinal = TagPush | TagRekey

	StreamKeyBytes    = chacha20poly1305.KeySize
	StreamHeaderBytes = chacha20poly1305.NonceSizeX
	// XChaCha20Poly1305IetfABYTES links to crypto_secretstream_xchacha20poly1305_ABYTES
	XChaCha20Poly1305IetfABYTES = 16 + 1
)

const cryptoCoreHchacha20InputBytes = 16

/* const crypto_secretstream_xchacha20poly1305_INONCEBYTES = 8 */
const cryptoSecretStreamXchacha20poly1305Counterbytes = 4

var pad0 [16]byte

var invalidKey = errors.New("invalid key")
var invalidInput = errors.New("invalid input")
var cryptoFailure = errors.New("crypto failed")

// crypto_secretstream_xchacha20poly1305_state
type streamState struct {
	k     [StreamKeyBytes]byte
	nonce [chacha20poly1305.NonceSize]byte
	pad   [8]byte
}

func (s *streamState) reset() {
	for i := range s.nonce {
		s.nonce[i] = 0
	}
	s.nonce[0] = 1
}

type Encryptor interface {
	Push(m []byte, tag byte) ([]byte, error)
}

type Decryptor interface {
	Pull(m []byte) ([]byte, byte, error)
}

type encryptor struct {
	streamState
}

type decryptor struct {
	streamState
}

func NewStreamKey() []byte {
	k := make([]byte, chacha20poly1305.KeySize)
	_, _ = rand.Read(k)
	return k
}

func NewEncryptor(key []byte) (Encryptor, []byte, error) {
	if len(key) != StreamKeyBytes {
		return nil, nil, invalidKey
	}

	header := make([]byte, StreamHeaderBytes)
	_, _ = rand.Read(header)

	stream := &encryptor{}

	k, err := chacha20.HChaCha20(key[:], header[:16])
	if err != nil {
		//fmt.Printf("error: %v", err)
		return nil, nil, err
	}
	copy(stream.k[:], k)
	stream.reset()

	for i := range stream.pad {
		stream.pad[i] = 0
	}

	for i, b := range header[cryptoCoreHchacha20InputBytes:] {
		stream.nonce[i+cryptoSecretStreamXchacha20poly1305Counterbytes] = b
	}
	// fmt.Printf("stream: %+v\n", stream.streamState)

	return stream, header, nil
}

func (s *encryptor) Push(plain []byte, tag byte) ([]byte, error) {
	var err error

	//crypto_onetimeauth_poly1305_state poly1305_state;
	var poly *poly1305.MAC

	//unsigned char                     block[64U];
	var block [64]byte

	//unsigned char                     slen[8U];
	var slen [8]byte

	//unsigned char                    *c;
	//unsigned char                    *mac;
	//
	//if (outlen_p != NULL) {
	//*outlen_p = 0U;
	//}

	mlen := len(plain)
	//if (mlen > crypto_secretstream_xchacha20poly1305_MESSAGEBYTES_MAX) {
	//sodium_misuse();
	//}

	out := make([]byte, mlen+XChaCha20Poly1305IetfABYTES)

	chacha, err := chacha20.NewUnauthenticatedCipher(s.k[:], s.nonce[:])
	if err != nil {
		return nil, err
	}
	//crypto_stream_chacha20_ietf(block, sizeof block, state->nonce, state->k);
	chacha.XORKeyStream(block[:], block[:])

	//crypto_onetimeauth_poly1305_init(&poly1305_state, block);
	var poly_init [32]byte
	copy(poly_init[:], block[:])
	poly = poly1305.New(&poly_init)

	// TODO add support for add data
	//sodium_memzero(block, sizeof block);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, ad, adlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, _pad0,
	//(0x10 - adlen) & 0xf);

	//memset(block, 0, sizeof block);
	//block[0] = tag;
	memZero(block[:])
	block[0] = tag

	//
	//crypto_stream_chacha20_ietf_xor_ic(block, block, sizeof block, state->nonce, 1U, state->k);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, block, sizeof block);
	//out[0] = block[0];
	chacha.XORKeyStream(block[:], block[:])
	_, _ = poly.Write(block[:])
	out[0] = block[0]

	//
	//c = out + (sizeof tag);
	c := out[1:]
	//crypto_stream_chacha20_ietf_xor_ic(c, m, mlen, state->nonce, 2U, state->k);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, c, mlen);
	//crypto_onetimeauth_poly1305_update (&poly1305_state, _pad0, (0x10 - (sizeof block) + mlen) & 0xf);
	chacha.XORKeyStream(c, plain)
	_, _ = poly.Write(c[:mlen])
	padlen := (0x10 - len(block) + mlen) & 0xf
	_, _ = poly.Write(pad0[:padlen])

	//
	//STORE64_LE(slen, (uint64_t) adlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, slen, sizeof slen);
	binary.LittleEndian.PutUint64(slen[:], uint64(0))
	_, _ = poly.Write(slen[:])

	//STORE64_LE(slen, (sizeof block) + mlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, slen, sizeof slen);
	binary.LittleEndian.PutUint64(slen[:], uint64(len(block)+mlen))
	_, _ = poly.Write(slen[:])

	//
	//mac = c + mlen;
	//crypto_onetimeauth_poly1305_final(&poly1305_state, mac);
	mac := c[mlen:]
	copy(mac, poly.Sum(nil))
	//sodium_memzero(&poly1305_state, sizeof poly1305_state);
	//

	//XOR_BUF(STATE_INONCE(state), mac, crypto_secretstream_xchacha20poly1305_INONCEBYTES);
	//sodium_increment(STATE_COUNTER(state), crypto_secretstream_xchacha20poly1305_COUNTERBYTES);
	xorBuf(s.nonce[cryptoSecretStreamXchacha20poly1305Counterbytes:], mac)
	bufInc(s.nonce[:cryptoSecretStreamXchacha20poly1305Counterbytes])

	// TODO
	//if ((tag & crypto_secretstream_xchacha20poly1305_TAG_REKEY) != 0 ||
	//sodium_is_zero(STATE_COUNTER(state),
	//crypto_secretstream_xchacha20poly1305_COUNTERBYTES)) {
	//crypto_secretstream_xchacha20poly1305_rekey(state);
	//}

	//if (outlen_p != NULL) {
	//*outlen_p = crypto_secretstream_xchacha20poly1305_ABYTES + mlen;
	//}

	//return 0;
	return out, nil
}

func NewDecryptor(key, header []byte) (Decryptor, error) {
	stream := &decryptor{}

	//crypto_core_hchacha20(state->k, in, k, NULL);
	k, err := chacha20.HChaCha20(key, header[:16])
	if err != nil {
		fmt.Printf("error: %v", err)
		return nil, err
	}
	copy(stream.k[:], k)

	//_crypto_secretstream_xchacha20poly1305_counter_reset(state);
	stream.reset()

	//memcpy(STATE_INONCE(state), in + crypto_core_hchacha20_INPUTBYTES,
	//	crypto_secretstream_xchacha20poly1305_INONCEBYTES);
	copy(stream.nonce[cryptoSecretStreamXchacha20poly1305Counterbytes:],
		header[cryptoCoreHchacha20InputBytes:])

	//memset(state->_pad, 0, sizeof state->_pad);
	copy(stream.pad[:], pad0[:])

	//fmt.Printf("decryptor: %+v\n", stream.streamState)

	return stream, nil
}

func (s *decryptor) Pull(cipher []byte) ([]byte, byte, error) {
	cipherLen := len(cipher)

	//crypto_onetimeauth_poly1305_state poly1305_state;
	var poly1305State [32]byte

	//unsigned char                     block[64U];
	var block [64]byte
	//unsigned char                     slen[8U];
	var slen [8]byte

	//unsigned char                     mac[crypto_onetimeauth_poly1305_BYTES];
	//const unsigned char              *c;
	//const unsigned char              *stored_mac;
	//unsigned long long                mlen; // length of the returned message
	//unsigned char                     tag; // for the return value
	//
	//if (mlen_p != NULL) {
	//*mlen_p = 0U;
	//}
	//if (tag_p != NULL) {
	//*tag_p = 0xff;
	//}

	/*
		if (inlen < crypto_secretstream_xchacha20poly1305_ABYTES) {
		return -1;
		}
		mlen = inlen - crypto_secretstream_xchacha20poly1305_ABYTES;
	*/
	if cipherLen < XChaCha20Poly1305IetfABYTES {
		return nil, 0, invalidInput
	}
	mlen := cipherLen - XChaCha20Poly1305IetfABYTES

	//if (mlen > crypto_secretstream_xchacha20poly1305_MESSAGEBYTES_MAX) {
	//sodium_misuse();
	//}

	//crypto_stream_chacha20_ietf(block, sizeof block, state->nonce, state->k);
	chacha, err := chacha20.NewUnauthenticatedCipher(s.k[:], s.nonce[:])
	if err != nil {
		return nil, 0, err
	}
	chacha.XORKeyStream(block[:], block[:])

	//crypto_onetimeauth_poly1305_init(&poly1305_state, block);

	copy(poly1305State[:], block[:])
	poly := poly1305.New(&poly1305State)

	// TODO
	//sodium_memzero(block, sizeof block);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, ad, adlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, _pad0,
	//(0x10 - adlen) & 0xf);
	//

	//memset(block, 0, sizeof block);
	//block[0] = in[0];
	//crypto_stream_chacha20_ietf_xor_ic(block, block, sizeof block, state->nonce, 1U, state->k);
	memZero(block[:])
	block[0] = cipher[0]
	chacha.XORKeyStream(block[:], block[:])

	//tag = block[0];
	//block[0] = in[0];
	//crypto_onetimeauth_poly1305_update(&poly1305_state, block, sizeof block);
	tag := block[0]
	block[0] = cipher[0]
	if _, err = poly.Write(block[:]); err != nil {
		return nil, 0, err
	}

	//c = in + (sizeof tag);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, c, mlen);
	//crypto_onetimeauth_poly1305_update (&poly1305_state, _pad0, (0x10 - (sizeof block) + mlen) & 0xf);
	c := cipher[1:]
	if _, err = poly.Write(c[:mlen]); err != nil {
		return nil, 0, err
	}
	padLen := (0x10 - len(block) + mlen) & 0xf
	if _, err = poly.Write(pad0[:padLen]); err != nil {
		return nil, 0, err
	}

	//
	//STORE64_LE(slen, (uint64_t) adlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, slen, sizeof slen);
	binary.LittleEndian.PutUint64(slen[:], uint64(0))
	if _, err = poly.Write(slen[:]); err != nil {
		return nil, 0, err
	}

	//STORE64_LE(slen, (sizeof block) + mlen);
	//crypto_onetimeauth_poly1305_update(&poly1305_state, slen, sizeof slen);
	binary.LittleEndian.PutUint64(slen[:], uint64(len(block)+mlen))
	if _, err = poly.Write(slen[:]); err != nil {
		return nil, 0, err
	}

	//
	//crypto_onetimeauth_poly1305_final(&poly1305_state, mac);
	//sodium_memzero(&poly1305_state, sizeof poly1305_state);

	mac := poly.Sum(nil)
	memZero(poly1305State[:])

	//stored_mac = c + mlen;
	//if (sodium_memcmp(mac, stored_mac, sizeof mac) != 0) {
	//sodium_memzero(mac, sizeof mac);
	//return -1;
	//}
	storedMac := c[mlen:]
	if !bytes.Equal(mac, storedMac) {
		memZero(mac)
		return nil, 0, cryptoFailure
	}

	//crypto_stream_chacha20_ietf_xor_ic(m, c, mlen, state->nonce, 2U, state->k);
	//XOR_BUF(STATE_INONCE(state), mac, crypto_secretstream_xchacha20poly1305_INONCEBYTES);
	//sodium_increment(STATE_COUNTER(state), crypto_secretstream_xchacha20poly1305_COUNTERBYTES);
	m := make([]byte, mlen)
	chacha.XORKeyStream(m, c[:mlen])

	xorBuf(s.nonce[cryptoSecretStreamXchacha20poly1305Counterbytes:], mac)
	bufInc(s.nonce[:cryptoSecretStreamXchacha20poly1305Counterbytes])

	// TODO
	//if ((tag & crypto_secretstream_xchacha20poly1305_TAG_REKEY) != 0 ||
	//sodium_is_zero(STATE_COUNTER(state),
	//crypto_secretstream_xchacha20poly1305_COUNTERBYTES)) {
	//crypto_secretstream_xchacha20poly1305_rekey(state);
	//}

	//if (mlen_p != NULL) {
	//*mlen_p = mlen;
	//}
	//if (tag_p != NULL) {
	//*tag_p = tag;
	//}
	//return 0;
	return m, tag, nil
}
