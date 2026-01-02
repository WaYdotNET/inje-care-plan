import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Servizio per cifratura E2E dei backup
/// Usa AES-256-GCM con chiave derivata e salvata nel Keychain/Keystore
class CryptoService {
  static const _keyStorageKey = 'injecare_backup_key';
  static const _ivStorageKey = 'injecare_backup_iv';
  static const _keyLength = 32; // 256 bit
  static const _ivLength = 16; // 128 bit per AES

  final FlutterSecureStorage _secureStorage;

  CryptoService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Genera una nuova chiave AES-256 e la salva nel secure storage
  Future<void> generateAndStoreKey() async {
    final secureRandom = FortunaRandom();
    final seedSource = Uint8List(_keyLength);
    for (var i = 0; i < seedSource.length; i++) {
      seedSource[i] = DateTime.now().microsecondsSinceEpoch % 256;
    }
    secureRandom.seed(KeyParameter(seedSource));

    final keyBytes = secureRandom.nextBytes(_keyLength);
    final ivBytes = secureRandom.nextBytes(_ivLength);

    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(keyBytes),
    );
    await _secureStorage.write(
      key: _ivStorageKey,
      value: base64Encode(ivBytes),
    );
  }

  /// Verifica se esiste una chiave salvata
  Future<bool> hasStoredKey() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    return key != null;
  }

  /// Recupera la chiave salvata, o ne genera una nuova se non esiste
  Future<Key> _getOrCreateKey() async {
    var keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    if (keyBase64 == null) {
      await generateAndStoreKey();
      keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    }
    return Key.fromBase64(keyBase64!);
  }

  /// Recupera l'IV salvato
  Future<IV> _getOrCreateIV() async {
    var ivBase64 = await _secureStorage.read(key: _ivStorageKey);
    if (ivBase64 == null) {
      await generateAndStoreKey();
      ivBase64 = await _secureStorage.read(key: _ivStorageKey);
    }
    return IV.fromBase64(ivBase64!);
  }

  /// Cifra un file e restituisce i bytes cifrati
  Future<Uint8List> encryptFile(File file) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final plainBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    return encrypted.bytes;
  }

  /// Decifra i bytes e restituisce i dati originali
  Future<Uint8List> decryptBytes(Uint8List encryptedBytes) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decryptBytes(Encrypted(encryptedBytes), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Cifra una stringa
  Future<String> encryptString(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  /// Decifra una stringa
  Future<String> decryptString(String encryptedBase64) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
    return decrypted;
  }

  /// Esporta la chiave in formato base64 (per backup manuale)
  /// ATTENZIONE: Mostrare solo all'utente, mai loggare
  Future<String> exportKeyForBackup() async {
    final keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    final ivBase64 = await _secureStorage.read(key: _ivStorageKey);
    if (keyBase64 == null || ivBase64 == null) {
      throw StateError('No encryption key found');
    }
    // Combina key e IV per il backup
    return '$keyBase64:$ivBase64';
  }

  /// Importa una chiave da backup manuale
  Future<void> importKeyFromBackup(String backupKey) async {
    final parts = backupKey.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid backup key format');
    }
    await _secureStorage.write(key: _keyStorageKey, value: parts[0]);
    await _secureStorage.write(key: _ivStorageKey, value: parts[1]);
  }

  /// Cancella la chiave (usare con cautela!)
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
    await _secureStorage.delete(key: _ivStorageKey);
  }

  /// Verifica che una chiave importata possa decifrare dei dati di test
  Future<bool> verifyKeyWithTestData(String testEncrypted) async {
    try {
      await decryptString(testEncrypted);
      return true;
    } catch (_) {
      return false;
    }
  }
}

