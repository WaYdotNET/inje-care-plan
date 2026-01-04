import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:injecare_plan/core/services/crypto_provider.dart';
import 'package:injecare_plan/core/services/crypto_service.dart';

void main() {
  group('cryptoServiceProvider', () {
    test('provides CryptoService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cryptoService = container.read(cryptoServiceProvider);

      expect(cryptoService, isA<CryptoService>());
    });

    test('provides same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(cryptoServiceProvider);
      final second = container.read(cryptoServiceProvider);

      expect(identical(first, second), true);
    });

    test('crypto service can derive keys', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cryptoService = container.read(cryptoServiceProvider);
      final key = cryptoService.deriveKeyFromPassword('testpassword', Uint8List(16));

      expect(key, hasLength(32)); // 32 bytes key
    });

    test('crypto service can encrypt and decrypt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cryptoService = container.read(cryptoServiceProvider);
      final testData = 'Hello, World!';
      final password = 'securepassword123';

      final encrypted = await cryptoService.encryptBytesWithPassword(
        Uint8List.fromList(testData.codeUnits),
        password,
      );

      final decrypted = await cryptoService.decryptBytesWithPassword(
        encrypted,
        password,
      );

      expect(String.fromCharCodes(decrypted), testData);
    });
  });
}
