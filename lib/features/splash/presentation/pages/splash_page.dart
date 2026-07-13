import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _draw;
  late final Animation<double> _breath;
  late final Animation<double> _glow;
  late final Animation<double> _brand;
  late final Animation<double> _tagline;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _draw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
    );
    _breath = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.72, curve: Curves.linear),
      ),
    );
    _brand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.72, curve: Curves.easeOutCubic),
    );
    _tagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 0.82, curve: Curves.easeOut),
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
    );

    _controller.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    // TEMP: always show onboarding for review — revert after feedback.
    context.go('/onboarding');
    // final done = sl<SettingsRepository>().isOnboardingComplete;
    // context.go(done ? '/app/today' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6EF),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final breath = _controller.value < 0.4 ? 1.0 : _breath.value;

          return Opacity(
            opacity: (1 - _exit.value).clamp(0.0, 1.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/branding/pulse_splash_v2.png',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF7FAF3).withValues(alpha: 0.15),
                        const Color(0xFFE8EBE6).withValues(alpha: 0.35),
                        PulseColors.canvasSoft.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Transform.scale(
                        scale: 0.92 + (0.08 * _draw.value),
                        child: Opacity(
                          opacity: Curves.easeOut.transform(
                            _draw.value.clamp(0.0, 1.0),
                          ),
                          child: SplashGlassMark(
                            progress: _draw.value,
                            breath: breath,
                            glow: _glow.value,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Opacity(
                        opacity: _brand.value,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - _brand.value)),
                          child: Text(
                            'PULSE',
                            style: PulseTypography.splashWordmark(
                              color: PulseColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: _tagline.value,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - _tagline.value)),
                          child: Text(
                            'your day, in rhythm',
                            style: PulseTypography.bodyMd(
                              color: PulseColors.body,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      Opacity(
                        opacity: _tagline.value * 0.7,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Text(
                            'habits · focus · calm',
                            style: PulseTypography.caption(
                              color: PulseColors.mute,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
