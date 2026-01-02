import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crypto_service.dart';

/// Provider singleton per CryptoService
final cryptoServiceProvider = Provider<CryptoService>((ref) {
  return CryptoService();
});
