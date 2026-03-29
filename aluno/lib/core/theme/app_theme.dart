import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extensão do tema para injeção de cores semânticas customizadas.
/// Garante que o acesso às cores respeita a árvore de contexto (Theme.of).
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color error;
  final Color warning;

  const AppColorsExtension({
    required this.success,
    required this.error,
    required this.warning,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

class AppTheme {
  // Paleta Cromática Institucional (Otimização High-Contrast OLED)
  static const Color backgroundPrimary = Color(0xFF121212);
  static const Color surfaceSecondary = Color(0xFF1E1E1E);
  static const Color brandAccent = Color(0xFF00B140);
  
  // Cores Semânticas
  static const Color successState = Color(0xFF00E676);
  static const Color errorState = Color(0xFFCF6679);
  static const Color warningState = Color(0xFFFFB300); // Adicionado conforme README
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);

  static ThemeData get darkTheme {
    // Inicialização da tipografia base com Inter
    final baseTextTheme = Typography.material2021().white;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      primaryColor: brandAccent,
      colorScheme: const ColorScheme.dark(
        primary: brandAccent,
        onPrimary: textPrimary,
        secondary: successState,
        surface: surfaceSecondary,
        onSurface: textPrimary,
        error: errorState,
        onError: textPrimary,
      ),
      // Injeção da extensão de cores customizadas
      extensions: const [
        AppColorsExtension(
          success: successState,
          error: errorState,
          warning: warningState,
        ),
      ],
      // Tipografia M3 integral para evitar fallbacks de fonte
      textTheme: interTextTheme.copyWith(
        displayLarge: interTextTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(fontSize: 16, color: textPrimary),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(fontSize: 14, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceSecondary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0, // Previne o overlay color nativo do M3 no scroll
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceSecondary,
        elevation: 0, // Reduzido a 0 para cumprir métricas flat do M3; contorno tratado localmente se necessário
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandAccent,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}