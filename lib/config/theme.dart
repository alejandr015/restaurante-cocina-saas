import 'package:flutter/material.dart';

/// Paleta y estilos centralizados de la app.
/// Los colores de estados (rojo/amarillo/verde) son fijos y vienen
/// del enum EstadoPedido. El color del restaurante se carga dinámico
/// desde la BD (ver AuthService.restaurante['color_primario']).
class AppTheme {
  // ---- Estados de pedido ----
  static const Color rojo = Color(0xFFE24B4A);
  static const Color rojoOscuro = Color(0xFF791F1F);
  static const Color rojoFondo = Color(0xFFFCEBEB);

  static const Color amarillo = Color(0xFFEF9F27);
  static const Color amarilloOscuro = Color(0xFF633806);
  static const Color amarilloFondo = Color(0xFFFAEEDA);

  static const Color verde = Color(0xFF639922);
  static const Color verdeOscuro = Color(0xFF27500A);
  static const Color verdeFondo = Color(0xFFEAF3DE);

  // ---- Neutros ----
  static const Color fondo = Color(0xFFF7F6F2);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFE5E3DB);
  static const Color textoPrimario = Color(0xFF1A1A19);
  static const Color textoSecundario = Color(0xFF73726C);
  static const Color textoTerciario = Color(0xFFA5A39B);

  /// Convierte un color hex en formato '#E24B4A' a Color de Flutter
  static Color hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
  }

  /// Tema base de la aplicación
  static ThemeData tema({Color? colorPrimario}) {
    final primary = colorPrimario ?? rojo;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        surface: superficie,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borde, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textoPrimario,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textoPrimario,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textoPrimario,
        ),
        bodyMedium: TextStyle(fontSize: 13, color: textoSecundario),
        bodySmall: TextStyle(fontSize: 11, color: textoTerciario),
      ),
    );
  }
}
