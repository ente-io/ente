import 'dart:convert';
import 'package:flutter/material.dart';
import 'samples.dart';

typedef void SampleFunc(Function(Object) print);
typedef Future SampleFuncAsync(Function(Object) print);

class Section extends Topic {
  Section(String title) : super(title);
}

class Topic {
  final String title;
  final String? description;
  final String? url;
  final List<Sample>? samples;

  Topic(this.title, {this.description, this.url, this.samples});
}

class Sample {
  final String name;
  final SampleFunc? func;
  final SampleFuncAsync? funcAsync;
  String? title;
  String? description;
  String? code;

  Sample(this.name, {this.func, this.funcAsync});
}

Future<List<Topic>> buildToc(BuildContext context) async {
  final samples = Samples();

  final toc = [
    Section('Common'),
    Topic('APIs',
        description:
            'The flutter_sodium library contains two sets of APIs, a core API and a high-level API. The core API maps native libsodium functions 1:1 to Dart equivalents. The high-level API provides Dart-friendly, opinionated access to libsodium.',
        samples: <Sample>[
          Sample('api1', func: samples.api1),
          Sample('api2', func: samples.api2)
        ]),
    Topic('Random data',
        description:
            'Provides a set of functions to generate unpredictable data, suitable for creating secret keys.',
        url: 'https://libsodium.gitbook.io/doc/generating_random_data/',
        samples: <Sample>[
          Sample('random1', func: samples.random1),
          Sample('random2', func: samples.random2),
          Sample('random3', func: samples.random3)
        ]),
    Topic('Encoding',
        description: 'Encode byte sequence to string and vice versa.',
        url: 'https://libsodium.gitbook.io/doc/helpers',
        samples: <Sample>[
          Sample('encoding1', func: samples.encoding1),
          Sample('encoding2', func: samples.encoding2)
        ]),
    Topic('Padding',
        description: 'Append padding data',
        url: 'https://libsodium.gitbook.io/doc/padding',
        samples: <Sample>[Sample('padding1', func: samples.padding1)]),
    Topic('About',
        description: 'Provides libsodium version, runtime and algorithm info.',
        url: 'https://libsodium.gitbook.io/doc/',
        samples: <Sample>[
          Sample('about1', func: samples.about1),
          Sample('about2', func: samples.about2),
          Sample('about3', func: samples.about3)
        ]),
    Section('Secret-key cryptography'),
    Topic('Authenticated encryption',
        description: 'Secret-key encryption and verification',
        url:
            'https://libsodium.gitbook.io/doc/secret-key_cryptography/secretbox',
        samples: <Sample>[
          Sample('secret1', func: samples.secret1),
          Sample('secret2', func: samples.secret2)
        ]),
    Topic('Authentication',
        description:
            'Computes an authentication tag for a message and a secret key, and provides a way to verify that a given tag is valid for a given message and a key.',
        url:
            'https://libsodium.gitbook.io/doc/secret-key_cryptography/secret-key_authentication',
        samples: <Sample>[
          Sample('auth1', func: samples.auth1),
        ]),
    Topic('Original ChaCha20-Poly1305',
        description: 'Authenticated Encryption with Additional Data.',
        url:
            'https://libsodium.gitbook.io/doc/secret-key_cryptography/aead/chacha20-poly1305/original_chacha20-poly1305_construction',
        samples: <Sample>[
          Sample('chacha1', func: samples.chacha1),
          Sample('chacha2', func: samples.chacha2)
        ]),
    Topic('IETF ChaCha20-Poly1305',
        description: 'Authenticated Encryption with Additional Data',
        url:
            'https://libsodium.gitbook.io/doc/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction',
        samples: <Sample>[
          Sample('chachaietf1', func: samples.chachaietf1),
          Sample('chachaietf2', func: samples.chachaietf2)
        ]),
    Topic('XChaCha20-Poly1305',
        description: 'Authenticated Encryption with Additional Data.',
        url:
            'https://libsodium.gitbook.io/doc/secret-key_cryptography/aead/chacha20-poly1305/xchacha20-poly1305_construction',
        samples: <Sample>[
          Sample('xchachaietf1', func: samples.xchachaietf1),
          Sample('xchachaietf2', func: samples.xchachaietf2)
        ]),
    Section('Public-key cryptography'),
    Topic('Authenticated encryption',
        description: 'Public-key authenticated encryption',
        url:
            'https://libsodium.gitbook.io/doc/public-key_cryptography/authenticated_encryption',
        samples: <Sample>[
          Sample('box1', func: samples.box1),
          Sample('box2', func: samples.box2),
          Sample('box3', func: samples.box3),
          Sample('box4', func: samples.box4)
        ]),
    Topic('Public-key signatures',
        description:
            'Computes a signature for a message using a secret key, and provides verification using a public key.',
        url:
            'https://libsodium.gitbook.io/doc/public-key_cryptography/public-key_signatures',
        samples: <Sample>[
          Sample('sign1', func: samples.sign1),
          Sample('sign2', func: samples.sign2),
          Sample('sign3', funcAsync: samples.sign3),
          Sample('sign4', func: samples.sign4)
        ]),
    Topic('Sealed boxes',
        description:
            'Anonymously send encrypted messages to a recipient given its public key.',
        url: 'https://libsodium.gitbook.io/doc/public-key_cryptography/sealed_boxes',
        samples: <Sample>[Sample('box5', func: samples.box5)]),
    Section('Hashing'),
    Topic('Generic hashing',
        description:
            'Computes a fixed-length fingerprint for an arbitrary long message using the BLAKE2b algorithm.',
        url: 'https://libsodium.gitbook.io/doc/hashing/generic_hashing',
        samples: <Sample>[
          Sample('generic1', func: samples.generic1),
          Sample('generic2', func: samples.generic2),
          Sample('generic3', funcAsync: samples.generic3),
          Sample('generic4', funcAsync: samples.generic4)
        ]),
    Topic('Short-input hashing',
        description: 'Computes short hashes using the SipHash-2-4 algorithm.',
        url: 'https://libsodium.gitbook.io/doc/hashing/short-input_hashing',
        samples: <Sample>[Sample('shorthash1', func: samples.shorthash1)]),
    Topic('Password hashing',
        description:
            'Provides an Argon2 password hashing scheme implementation.',
        url:
            'https://libsodium.gitbook.io/doc/password_hashing/the_argon2i_function',
        samples: <Sample>[
          Sample('pwhash1', func: samples.pwhash1),
          Sample('pwhash2', func: samples.pwhash2),
          Sample('pwhash3', funcAsync: samples.pwhash3),
        ]),
    Section('Key functions'),
    Topic('Key derivation',
        description: 'Derive secret subkeys from a single master key.',
        url: 'https://libsodium.gitbook.io/doc/key_derivation/',
        samples: <Sample>[Sample('kdf1', func: samples.kdf1)]),
    Topic('Key exchange',
        description: 'Securely compute a set of shared keys.',
        url: 'https://libsodium.gitbook.io/doc/key_exchange/',
        samples: <Sample>[Sample('kx1', func: samples.kx1)]),
    Section('Advanced'),
    Topic('SHA-2',
        description: 'SHA-512 hash functions',
        url: 'https://libsodium.gitbook.io/doc/advanced/sha-2_hash_function',
        samples: <Sample>[Sample('hash1', func: samples.hash1)]),
    Topic('Diffie-Hellman',
        description: 'Perform scalar multiplication of elliptic curve points',
        url: 'https://libsodium.gitbook.io/doc/advanced/scalar_multiplication',
        samples: <Sample>[
          Sample('scalarmult1', funcAsync: samples.scalarmult1)
        ]),
    Topic('One-time authentication',
        description: 'Secret-key single-message authentication using Poly1305',
        url: 'https://libsodium.gitbook.io/doc/advanced/poly1305',
        samples: <Sample>[
          Sample('onetime1', func: samples.onetime1),
          Sample('onetime2', funcAsync: samples.onetime2)
        ]),
    Topic('Stream ciphers',
        description: 'Generate pseudo-random data from a key',
        url: 'https://libsodium.gitbook.io/doc/advanced/stream_ciphers',
        samples: <Sample>[Sample('stream1', func: samples.stream1)]),
    Topic('Ed25519 To Curve25519',
        description:
            'Ed25519 keys can be converted to X25519 keys, so that the same key pair can be used both for authenticated encryption (crypto_box) and for signatures (crypto_sign).',
        url: 'https://download.libsodium.org/doc/advanced/ed25519-curve25519',
        samples: <Sample>[Sample('sign5', func: samples.sign5)])
  ];

  // load asset samples.dart for code snippets
  final src =
      await DefaultAssetBundle.of(context).loadString('lib/samples.dart');

  // iterate all samples in the toc, and parse title, description and code snippet
  for (var topic in toc) {
    if (topic.samples != null) {
      for (var sample in topic.samples!) {
        final beginTag = '// BEGIN ${sample.name}:';
        final begin = src.indexOf(beginTag);
        assert(begin != -1);

        // parse title
        final beginTitle = begin + beginTag.length;
        final endTitle = src.indexOf(':', beginTitle);
        assert(endTitle != -1);
        sample.title = src.substring(beginTitle, endTitle).trim();

        // parse description
        final endDescription = src.indexOf('\n', endTitle);
        assert(endDescription != -1);
        sample.description = src.substring(endTitle + 1, endDescription).trim();

        final end = src.indexOf('// END ${sample.name}', endDescription);
        assert(end != -1);

        sample.code = _formatCode(src.substring(endDescription, end));
      }
    }
  }

  return toc;
}

String _formatCode(String code) {
  final result = StringBuffer();
  final lines = LineSplitter.split(code).toList();
  int indent = -1;
  for (var i = 0; i < lines.length; i++) {
    String line = lines[i];
    // skip empty first and last lines
    if (line.trim().length == 0 && (i == 0 || i == lines.length - 1)) {
      continue;
    }
    // determine indent
    if (indent == -1) {
      for (indent = 0; indent < line.length; indent++) {
        if (line[indent] != ' ') {
          break;
        }
      }
    }

    // remove indent from line
    if (line.startsWith(' ' * indent)) {
      line = line.substring(indent);
    }

    if (result.isNotEmpty) {
      result.writeln();
    }
    result.write(line);
  }
  return result.toString();
}
