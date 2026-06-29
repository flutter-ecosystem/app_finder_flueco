import 'package:flutter/material.dart';

ThemeData buildNightNeumorphicTheme() {
  const background = Color(0xFF0B1220);
  const surface = Color(0xFF101A2E);
  const text = Color(0xFFE8F0FF);
  const muted = Color(0xFF8EA4C8);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4EA1FF),
      brightness: Brightness.dark,
      surface: surface,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 28),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: muted),
      labelMedium: TextStyle(color: muted),
    ),
  );
}

class NeuContainer extends StatelessWidget {
  const NeuContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13213A), Color(0xFF08101D)],
        ),
        boxShadow: const [
          BoxShadow(offset: Offset(8, 8), blurRadius: 18, color: Color(0xAA050914)),
          BoxShadow(offset: Offset(-7, -7), blurRadius: 18, color: Color(0x221F3B68)),
        ],
        border: Border.all(color: const Color(0x1A7FB8FF)),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onTap,
      child: content,
    );
  }
}
