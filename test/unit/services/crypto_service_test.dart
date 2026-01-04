import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:injecare_plan/core/services/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('CryptoService.deriveKeyFromPassword', () {
    test('derives consistent key from same password and salt', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      const password = 'testPassword123';

      final key1 = cryptoService.deriveKeyFromPassword(password, salt);
      final key2 = cryptoService.deriveKeyFromPassword(password, salt);

      expect(key1, equals(key2));
    });

    test('derives different keys for different passwords', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      const password1 = 'testPassword123';
      const password2 = 'differentPassword';

      final key1 = cryptoService.deriveKeyFromPassword(password1, salt);
      final key2 = cryptoService.deriveKeyFromPassword(password2, salt);

      expect(key1, isNot(equals(key2)));
    });

    test('derives different keys for different salts', () {
      final salt1 = Uint8List.fromList(List.generate(16, (i) => i));
      final salt2 = Uint8List.fromList(List.generate(16, (i) => i + 1));
      const password = 'testPassword123';

      final key1 = cryptoService.deriveKeyFromPassword(password, salt1);
      final key2 = cryptoService.deriveKeyFromPassword(password, salt2);

      expect(key1, isNot(equals(key2)));
    });

    test('derived key has correct length (32 bytes for AES-256)', () {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      const password = 'testPassword123';

      final key = cryptoService.deriveKeyFromPassword(password, salt);

      expect(key.length, 32);
    });
  });

  group('CryptoService.encryptBytesWithPassword', () {
    test('encrypts data and returns result with salt and IV', () {
      final plainBytes = Uint8List.fromList('Hello, World!'.codeUnits);
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);

      // Result should be: 16 bytes salt + 16 bytes IV + encrypted data
      expect(encrypted.length, greaterThan(32));
    });

    test('encryption is non-deterministic (different each time)', () {
      final plainBytes = Uint8List.fromList('Hello, World!'.codeUnits);
      const password = 'testPassword123';

      final encrypted1 = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final encrypted2 = cryptoService.encryptBytesWithPassword(plainBytes, password);

      // Should be different due to random salt and IV
      expect(encrypted1, isNot(equals(encrypted2)));
    });
  });

  group('CryptoService.decryptBytesWithPassword', () {
    test('decrypts encrypted data correctly', () {
      final plainBytes = Uint8List.fromList('Hello, World!'.codeUnits);
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final decrypted = cryptoService.decryptBytesWithPassword(encrypted, password);

      expect(decrypted, equals(plainBytes));
    });

    test('decrypts longer data correctly', () {
      final plainBytes = Uint8List.fromList(
        List.generate(1000, (i) => i % 256),
      );
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final decrypted = cryptoService.decryptBytesWithPassword(encrypted, password);

      expect(decrypted, equals(plainBytes));
    });

    test('throws on invalid data (too short)', () {
      final shortData = Uint8List.fromList(List.generate(20, (i) => i));
      const password = 'testPassword123';

      expect(
        () => cryptoService.decryptBytesWithPassword(shortData, password),
        throwsArgumentError,
      );
    });

    test('fails with wrong password', () {
      final plainBytes = Uint8List.fromList('Hello, World!'.codeUnits);
      const password = 'testPassword123';
      const wrongPassword = 'wrongPassword';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);

      // Decryption with wrong password should throw an exception
      expect(
        () => cryptoService.decryptBytesWithPassword(encrypted, wrongPassword),
        throwsA(anything),
      );
    });
  });

  group('CryptoService.verifyPassword', () {
    test('returns true for correct password', () {
      final plainBytes = Uint8List.fromList('Test data'.codeUnits);
      const password = 'correctPassword';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final result = cryptoService.verifyPassword(encrypted, password);

      expect(result, isTrue);
    });

    test('returns false for incorrect password', () {
      final plainBytes = Uint8List.fromList('Test data'.codeUnits);
      const password = 'correctPassword';
      const wrongPassword = 'wrongPassword';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final result = cryptoService.verifyPassword(encrypted, wrongPassword);

      expect(result, isFalse);
    });

    test('returns false for invalid data', () {
      final invalidData = Uint8List.fromList(List.generate(10, (i) => i));
      const password = 'anyPassword';

      final result = cryptoService.verifyPassword(invalidData, password);

      expect(result, isFalse);
    });
  });

  group('CryptoService.isValidPassword (static)', () {
    test('returns true for password >= 8 characters', () {
      expect(CryptoService.isValidPassword('12345678'), isTrue);
      expect(CryptoService.isValidPassword('password123'), isTrue);
      expect(CryptoService.isValidPassword('averylongpassword'), isTrue);
    });

    test('returns false for password < 8 characters', () {
      expect(CryptoService.isValidPassword('1234567'), isFalse);
      expect(CryptoService.isValidPassword('short'), isFalse);
      expect(CryptoService.isValidPassword(''), isFalse);
    });
  });

  group('CryptoService.validatePassword (static)', () {
    test('returns null for valid password', () {
      expect(CryptoService.validatePassword('12345678'), isNull);
      expect(CryptoService.validatePassword('validpassword'), isNull);
    });

    test('returns error message for null password', () {
      expect(CryptoService.validatePassword(null), 'Inserisci una password');
    });

    test('returns error message for empty password', () {
      expect(CryptoService.validatePassword(''), 'Inserisci una password');
    });

    test('returns error message for short password', () {
      expect(
        CryptoService.validatePassword('short'),
        'La password deve avere almeno 8 caratteri',
      );
    });
  });

  group('Round-trip encryption/decryption', () {
    test('works with single byte data', () {
      final plainBytes = Uint8List.fromList([42]);
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final decrypted = cryptoService.decryptBytesWithPassword(encrypted, password);

      expect(decrypted, equals(plainBytes));
    });

    test('works with unicode data', () {
      final plainBytes = Uint8List.fromList('Ciao 🌍 世界'.codeUnits);
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final decrypted = cryptoService.decryptBytesWithPassword(encrypted, password);

      expect(decrypted, equals(plainBytes));
    });

    test('works with binary data', () {
      final plainBytes = Uint8List.fromList(List.generate(256, (i) => i));
      const password = 'testPassword123';

      final encrypted = cryptoService.encryptBytesWithPassword(plainBytes, password);
      final decrypted = cryptoService.decryptBytesWithPassword(encrypted, password);

      expect(decrypted, equals(plainBytes));
    });
  });
}
