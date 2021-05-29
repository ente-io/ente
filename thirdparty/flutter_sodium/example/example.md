```dart
import 'package:flutter_sodium/flutter_sodium.dart';

// initialize sodium (one-time)
Sodium.init();

// Password hashing (using Argon)
final password = 'my password';
final str = PasswordHash.hashStringStorage(password);

print(str);

// verify hash str
final valid = PasswordHash.verifyStorage(str, password);

assert(valid);
```
