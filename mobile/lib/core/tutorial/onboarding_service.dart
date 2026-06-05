import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../presentation/onboarding/onboarding_carousel.dart';

class OnboardingService {
  OnboardingService._();

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final String userId;
    try {
      final profile = await ref.read(profileStateProvider.future);
      userId = profile.id;
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarding_shown_$userId';
    final shown = prefs.getBool(key) ?? false;
    if (shown || !context.mounted) return;

    await prefs.setBool(key, true);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => const OnboardingCarousel(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Usado nas settings para repor o onboarding (útil para testes/suporte)
  static Future<void> reset(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_shown_$userId');
  }

  // Mostra sempre, ignorando se já foi visto (para testes/settings)
  static Future<void> showForced(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => const OnboardingCarousel(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

}