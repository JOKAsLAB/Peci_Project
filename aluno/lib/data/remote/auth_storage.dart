import 'package:flutter_riverpod/flutter_riverpod.dart';

// Guarda o token JWT em memória 
// (se pode migrar para flutter_secure_storage mais tarde)
final authTokenProvider = StateProvider<String?>((ref) => null);