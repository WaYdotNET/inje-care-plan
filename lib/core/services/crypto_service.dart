import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

/// Servizio per cifratura E2E dei backup
/// Usa AES-256-CBC con chiave derivata da password tramite PBKDF2
///
/// Formato file backup: [16 bytes salt][N bytes dati cifrati]
class CryptoService {
  static const _saltLength = 16;
  static const _keyLength = 32; // 256 bit
  static const _ivLength = 16; // 128 bit per AES
  static const _pbkdf2Iterations = 100000;

  CryptoService();

  /// Genera un salt random
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Genera un IV random
  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(_ivLength, (_) => random.nextInt(256)),
    );
  }

  /// Deriva una chiave AES-256 dalla password usando PBKDF2
  Uint8List deriveKeyFromPassword(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));

    return pbkdf2.process(Uint8List.fromList(password.codeUnits));
  }

  /// Cifra un file con password
  /// Restituisce: [16 bytes salt][16 bytes IV][N bytes dati cifrati]
  Future<Uint8List> encryptFileWithPassword(File file, String password) async {
    // Genera salt e IV random
    final salt = _generateSalt();
    final ivBytes = _generateIV();

    // Deriva chiave dalla password
    final keyBytes = deriveKeyFromPassword(password, salt);
    final key = Key(keyBytes);
    final iv = IV(ivBytes);

    // Cifra
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final plainBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    // Combina: salt + iv + dati cifrati
    final result = Uint8List(_saltLength + _ivLength + encrypted.bytes.length);
    result.setRange(0, _saltLength, salt);
    result.setRange(_saltLength, _saltLength + _ivLength, ivBytes);
    result.setRange(_saltLength + _ivLength, result.length, encrypted.bytes);

    return result;
  }

  /// Decifra bytes con password
  /// Input: [16 bytes salt][16 bytes IV][N bytes dati cifrati]
  Uint8List decryptBytesWithPassword(Uint8List encryptedData, String password) {
    if (encryptedData.length < _saltLength + _ivLength + 1) {
      throw ArgumentError('Dati cifrati non validi');
    }

    // Estrai salt e IV
    final salt = encryptedData.sublist(0, _saltLength);
    final ivBytes = encryptedData.sublist(_saltLength, _saltLength + _ivLength);
    final cipherBytes = encryptedData.sublist(_saltLength + _ivLength);

    // Deriva chiave dalla password
    final keyBytes = deriveKeyFromPassword(password, salt);
    final key = Key(keyBytes);
    final iv = IV(ivBytes);

    // Decifra
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decryptBytes(Encrypted(cipherBytes), iv: iv);

    return Uint8List.fromList(decrypted);
  }

  /// Cifra bytes con password (per uso generico)
  Uint8List encryptBytesWithPassword(Uint8List plainBytes, String password) {
    final salt = _generateSalt();
    final ivBytes = _generateIV();

    final keyBytes = deriveKeyFromPassword(password, salt);
    final key = Key(keyBytes);
    final iv = IV(ivBytes);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final result = Uint8List(_saltLength + _ivLength + encrypted.bytes.length);
    result.setRange(0, _saltLength, salt);
    result.setRange(_saltLength, _saltLength + _ivLength, ivBytes);
    result.setRange(_saltLength + _ivLength, result.length, encrypted.bytes);

    return result;
  }

  /// Verifica se una password può decifrare i dati
  bool verifyPassword(Uint8List encryptedData, String password) {
    try {
      decryptBytesWithPassword(encryptedData, password);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Valida la password (minimo 8 caratteri)
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Messaggio di errore per password non valida
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Inserisci una password';
    }
    if (password.length < 8) {
      return 'La password deve avere almeno 8 caratteri';
    }
    return null;
  }
}
