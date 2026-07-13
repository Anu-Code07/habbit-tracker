import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';
import 'package:pulse/features/splash/presentation/widgets/pulse_ripple_painter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _ripples;

  late final Animation<double> _fade;
  late final Animation<double> _rise;
  late final Animation<double> _breath;
  late final Animation<double> _tagline;
  late final Animation<double> _frame;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ripples = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();

    _fade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _rise = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _breath = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.3, 0.75, curve: Curves.linear),
      ),
    );
    _frame = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.1, 0.45, curve: Curves.easeOut),
    );
    _tagline = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    _exit = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
    );

    _intro.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final done = sl<SettingsRepository>().isOnboardingComplete;
    context.go(done ? '/app/today' : '/onboarding');
  }

  @override
  void dispose() {
    _intro.dispose();
    _ripples.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _ripples]),
        builder: (context, _) {
          final breath = _intro.value < 0.35 ? 1.0 : _breath.value;
          final exit = _exit.value;

          return Opacity(
            opacity: (1 - exit).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7FAF3),
                    Color(0xFFEEF5E7),
                    Color(0xFFE2EDD6),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: SplashConcentricPainter(t: _ripples.value),
                  ),
                  Center(
                    child: Opacity(
                      opacity: _fade.value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - _rise.value)),
                        child: Transform.scale(
                          scale: breath,
                          child: SplashFrameAccent(
                            opacity: _frame.value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 44,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'PULSE',
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    style: PulseTypography.splashWordmark(
                                      color: PulseColors.ink,
                                    ).copyWith(
                                      fontSize: 48,
                                      letterSpacing: 8,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Opacity(
                                    opacity: _tagline.value,
                                    child: Text(
                                      'your day, in rhythm',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.fraunces(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                        height: 1.3,
                                        color: PulseColors.body
                                            .withValues(alpha: 0.88),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
