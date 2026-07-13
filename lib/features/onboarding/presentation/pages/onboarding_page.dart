import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pulse/core/di/injection.dart';
import 'package:pulse/core/theme/habit_palette.dart';
import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';
import 'package:pulse/core/widgets/pulse_widgets.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(
        seedStarterHabits: sl<SeedStarterHabits>(),
        dedupeHabits: sl<DedupeHabits>(),
        settingsRepository: sl<SettingsRepository>(),
      ),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  static const _pageDuration = Duration(milliseconds: 420);
  static const _pageCurve = Curves.easeInOutCubic;

  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    context.read<OnboardingBloc>().add(OnboardingPageChanged(index));
    _controller.animateToPage(
      index,
      duration: _pageDuration,
      curve: _pageCurve,
    );
  }

  void _next() {
    final next = (_controller.page?.round() ?? 0) + 1;
    _controller.nextPage(duration: _pageDuration, curve: _pageCurve);
    if (next <= 3) {
      context.read<OnboardingBloc>().add(OnboardingPageChanged(next));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (p, c) =>
          p.isSubmitting && !c.isSubmitting && c.errorMessage == null,
      listener: (context, state) {
        context.go('/app/today');
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PulseAtmosphere(
          child: SafeArea(
            child: Column(
              children: [
                _OnboardingTopBar(onSkip: () => _goTo(3)),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    // Keep neighbors alive so layouts stay warm and skip rebuild jank.
                    allowImplicitScrolling: true,
                    onPageChanged: (i) => context
                        .read<OnboardingBloc>()
                        .add(OnboardingPageChanged(i)),
                    children: [
                      _HeroIntro(onNext: _next),
                      _NamePage(onNext: _next),
                      _RitualPage(onNext: _next),
                      const _PickHabitsPage(),
                    ],
                  ),
                ),
                const _OnboardingDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fixed-height chrome so Skip appearing/disappearing never shifts the page.
class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PulseSpacing.xl,
        PulseSpacing.md,
        PulseSpacing.xl,
        0,
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Text('PULSE', style: PulseTypography.brandMark()),
            const Spacer(),
            BlocSelector<OnboardingBloc, OnboardingState, bool>(
              selector: (s) => s.pageIndex < 3,
              builder: (context, showSkip) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: showSkip ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !showSkip,
                    child: TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: PulseTypography.bodySmStrong(
                          color: PulseColors.mute,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PulseSpacing.xl,
        0,
        PulseSpacing.xl,
        PulseSpacing.xl,
      ),
      child: PulseGlass(
        opacity: 0.4,
        blur: 14,
        borderRadius: BorderRadius.circular(PulseRadii.pill),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: BlocSelector<OnboardingBloc, OnboardingState, int>(
          selector: (s) => s.pageIndex,
          builder: (context, pageIndex) {
            return SizedBox(
              // Fixed width so expanding active pill doesn't nudge the chrome.
              width: 4 * 8 + 3 * 28 + 8 * 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final active = pageIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? PulseColors.ink
                          : PulseColors.mute.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(PulseRadii.pill),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shared title block so step pages share the same vertical rhythm.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: PulseTypography.displayMd()),
        const SizedBox(height: PulseSpacing.sm),
        Text(subtitle, style: PulseTypography.bodyMd()),
        const SizedBox(height: PulseSpacing.md),
        // Always reserve chip row height so pages don't jump when swiping.
        SizedBox(
          height: 32,
          child: trailing ?? const SizedBox.shrink(),
        ),
        const SizedBox(height: PulseSpacing.lg),
      ],
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),
          PulseGlass(
            opacity: 0.35,
            blur: 22,
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PulseRadii.lg),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/branding/pulse_onboarding_hero.webp',
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            PulseColors.ink.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(PulseSpacing.lg),
                        child: Text(
                          'Your day,\nin rhythm.',
                          style: PulseTypography.displaySm(
                            color: PulseColors.canvas,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: PulseSpacing.xxl),
          Text(
            'Build healthy habits with Pulse',
            style: PulseTypography.displayMd(),
          ),
          const SizedBox(height: PulseSpacing.md),
          Text(
            'A calm daily ritual for focus, streaks, and quiet progress — nothing noisy, nothing guilt-heavy.',
            style: PulseTypography.bodyLg(),
          ),
          const Spacer(flex: 2),
          PulsePrimaryButton(label: 'Get started', onPressed: onNext),
        ],
      ),
    );
  }
}

class _NamePage extends StatefulWidget {
  const _NamePage({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OnboardingBloc>().state.userName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          PulseGlass(
            tint: PulseColors.primaryPale,
            opacity: 0.55,
            padding: const EdgeInsets.all(PulseSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Okay, real talk.',
                  style: PulseTypography.displayMd(),
                ),
                const SizedBox(height: PulseSpacing.sm),
                Text(
                  'What should we yell when you crush a habit? (Softly. We’re civilized.)',
                  style: PulseTypography.bodyLg(),
                ),
                const SizedBox(height: PulseSpacing.xxl),
                TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofocus: false,
                  style: PulseTypography.displayXs(),
                  decoration: const InputDecoration(
                    hintText: 'Your name, nickname, alter ego…',
                  ),
                  onChanged: (value) => context
                      .read<OnboardingBloc>()
                      .add(OnboardingNameChanged(value)),
                  onSubmitted: (_) => widget.onNext(),
                ),
                const SizedBox(height: PulseSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in const [
                      'Sunny',
                      'Boss',
                      'Bean',
                      'Legend',
                    ])
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: () {
                          _controller.text = suggestion;
                          _controller.selection = TextSelection.collapsed(
                            offset: suggestion.length,
                          );
                          context
                              .read<OnboardingBloc>()
                              .add(OnboardingNameChanged(suggestion));
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          BlocSelector<OnboardingBloc, OnboardingState, bool>(
            selector: (s) => s.hasValidName,
            builder: (context, hasValidName) {
              return PulsePrimaryButton(
                label: hasValidName ? 'That’s me — continue' : 'Continue',
                onPressed: widget.onNext,
              );
            },
          ),
          const SizedBox(height: PulseSpacing.sm),
          TextButton(
            onPressed: widget.onNext,
            child: Text(
              'Skip for now',
              style: PulseTypography.bodySmStrong(color: PulseColors.mute),
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualPage extends StatelessWidget {
  const _RitualPage({required this.onNext});
  final VoidCallback onNext;

  static const _rituals = [
    (
      icon: Icons.check_circle_outline_rounded,
      title: 'Tap to complete',
      body: 'Colorful habit cards that feel good to finish.',
      tint: Color(0xFFFFF1C2),
    ),
    (
      icon: Icons.timer_outlined,
      title: 'Focus when it counts',
      body: 'Drop into a lime focus room and protect your attention.',
      tint: Color(0xFFE2F6D5),
    ),
    (
      icon: Icons.auto_graph_rounded,
      title: 'See your rhythm',
      body: 'Weekly insights that celebrate consistency, not perfection.',
      tint: Color(0xFFD6ECFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepHeader(
            title: 'Three quiet powers',
            subtitle: 'Pulse keeps the ritual simple so showing up stays easy.',
          ),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _rituals.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: PulseSpacing.md),
              itemBuilder: (context, index) {
                final item = _rituals[index];
                return PulseGlass(
                  tint: item.tint,
                  opacity: 0.55,
                  padding: const EdgeInsets.all(PulseSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: PulseColors.canvas.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(PulseRadii.lg),
                        ),
                        child: Icon(item.icon, color: PulseColors.ink),
                      ),
                      const SizedBox(width: PulseSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: PulseTypography.bodyMdStrong(),
                            ),
                            const SizedBox(height: 4),
                            Text(item.body, style: PulseTypography.bodySm()),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PulseSpacing.md),
          PulsePrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PickHabitsPage extends StatelessWidget {
  const _PickHabitsPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocSelector<OnboardingBloc, OnboardingState, int>(
            selector: (s) => s.selectedKeys.length,
            builder: (context, count) {
              return _StepHeader(
                title: 'What will you practice?',
                subtitle: 'Pick a few starters. You can reshape them anytime.',
                trailing: Align(
                  alignment: Alignment.centerLeft,
                  child: PulseGlass(
                    tint: PulseColors.primaryPale,
                    opacity: 0.7,
                    blur: 10,
                    borderRadius: BorderRadius.circular(PulseRadii.pill),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '$count selected',
                      style: PulseTypography.bodySmStrong(
                        color: PulseColors.positiveDeep,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              buildWhen: (p, c) => p.selectedKeys != c.selectedKeys,
              builder: (context, state) {
                return ListView(
                  physics: const BouncingScrollPhysics(),
                  children: OnboardingBloc.starters.entries.map((e) {
                    final selected = state.selectedKeys.contains(e.key);
                    final color = Color(e.value.color);
                    final icon = switch (e.key) {
                      'read' => HabitPalette.icons[0],
                      'workout' => HabitPalette.icons[1],
                      'meditate' => HabitPalette.icons[2],
                      'water' => HabitPalette.icons[3],
                      _ => HabitPalette.icons[4],
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: PulseSpacing.md),
                      child: PulseGlass(
                        tint: color,
                        opacity: selected ? 0.72 : 0.42,
                        borderOpacity: selected ? 0.85 : 0.4,
                        onTap: () => context
                            .read<OnboardingBloc>()
                            .add(OnboardingToggleStarter(e.key)),
                        padding: const EdgeInsets.all(PulseSpacing.lg),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    PulseColors.canvas.withValues(alpha: 0.55),
                                borderRadius:
                                    BorderRadius.circular(PulseRadii.md),
                              ),
                              child: Icon(icon, color: PulseColors.ink),
                            ),
                            const SizedBox(width: PulseSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.value.name,
                                    style: PulseTypography.bodyMdStrong(),
                                  ),
                                  Text(
                                    e.value.description,
                                    style: PulseTypography.bodySm(),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selected
                                    ? PulseColors.ink
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: PulseColors.ink,
                                  width: 2,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: PulseColors.primary,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          BlocBuilder<OnboardingBloc, OnboardingState>(
            buildWhen: (p, c) =>
                p.isSubmitting != c.isSubmitting ||
                p.errorMessage != c.errorMessage ||
                p.userName != c.userName ||
                p.selectedKeys != c.selectedKeys,
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.errorMessage != null) ...[
                    Text(
                      state.errorMessage!,
                      style:
                          PulseTypography.bodySm(color: PulseColors.negative),
                    ),
                    const SizedBox(height: PulseSpacing.sm),
                  ],
                  PulsePrimaryButton(
                    label: state.isSubmitting
                        ? 'Setting up…'
                        : state.userName.trim().isEmpty
                            ? 'Start my Pulse'
                            : 'Let’s go, ${state.userName.trim().split(RegExp(r'\s+')).first}',
                    onPressed: state.isSubmitting || state.selectedKeys.isEmpty
                        ? null
                        : () => context
                            .read<OnboardingBloc>()
                            .add(const OnboardingCompleted()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
