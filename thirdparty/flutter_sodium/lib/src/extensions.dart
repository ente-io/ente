import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'sodium_exception.dart';

extension Uint8Pointer on Pointer<Uint8> {
  Uint8List toList(int length) {
    final builder = BytesBuilder();
    for (var i = 0; i < length; i++) {
      builder.addByte(this[i]);
    }
    return builder.takeBytes();
  }

  Uint8List toNullTerminatedList(int maxLength) {
    final builder = BytesBuilder();
    for (var i = 0; i < maxLength; i++) {
      builder.addByte(this[i]);
      if (this[i] == 0) {
        break;
      }
    }
    return builder.takeBytes();
  }
}

extension Uint8ListExtensions on Uint8List {
  Pointer<Uint8> toPointer({int? size}) {
    final p = calloc<Uint8>(size ?? this.length);
    p.asTypedList(size ?? this.length).setAll(0, this);
    return p;
  }

  Uint8List toNullTerminatedList({int? maxLength}) {
    if ((maxLength == null || this.length < maxLength) && this.last != 0) {
      return new Uint8List(this.length + 1)..setAll(0, this);
    }

    // return unchanged
    return this;
  }
}

extension Result on int {
  void mustSucceed(String funcName) {
    if (this != 0) {
      throw SodiumException('$funcName failed with $this');
    }
  }
}
