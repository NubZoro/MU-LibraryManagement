import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _topAlignmentAnimation = AlignmentTween(
      begin: const Alignment(-2.0, -2.0),
      end: const Alignment(2.0, 2.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _bottomAlignmentAnimation = AlignmentTween(
      begin: const Alignment(-1.5, -1.5),
      end: const Alignment(1.5, 1.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
              colors: isDark
                  ? [
                      const Color(0xFF1A237E), // Deep blue
                      const Color(0xFF0D47A1), // Dark blue
                      const Color(0xFF1565C0), // Medium blue
                      const Color(0xFF1976D2), // Primary blue
                      const Color(0xFF1E88E5), // Light blue
                    ]
                  : [
                      const Color(0xFFE3F2FD), // Lightest blue
                      const Color(0xFFBBDEFB), // Very light blue
                      const Color(0xFF90CAF9), // Light blue
                      const Color(0xFF64B5F6), // Medium light blue
                      const Color(0xFF42A5F5), // Medium blue
                    ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
} 