import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crypto_service.dart';

/// Provider singleton per CryptoService
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});

/// Provider per verificare se esiste una chiave di cifratura
final hasEncryptionKeyProvider = FutureProvider<bool>((ref) async {
  final cryptoService = ref.watch(cryptoServiceProvider);
  return cryptoService.hasStoredKey();
});

