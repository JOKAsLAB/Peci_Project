import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/remote/student_repository.dart';

/// Carrega o perfil real do aluno directamente da API (/students/me).
/// Não depende do authProvider para evitar re-execuções.
final profileStateProvider = FutureProvider.autoDispose<StudentProfile>((ref) async {
  final repo = ref.read(studentRepositoryProvider);
  return await repo.getProfile();
});
