import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:pulse/core/theme/habit_palette.dart';
import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';
import 'package:pulse/features/settings/data/settings_repository.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

class OnboardingNameChanged extends OnboardingEvent {
  const OnboardingNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

class OnboardingToggleStarter extends OnboardingEvent {
  const OnboardingToggleStarter(this.key);
  final String key;

  @override
  List<Object?> get props => [key];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

class OnboardingState extends Equatable {
  const OnboardingState({
    this.pageIndex = 0,
    this.userName = '',
    this.selectedKeys = const {'read', 'workout', 'meditate'},
    this.isSubmitting = false,
    this.errorMessage,
  });

  final int pageIndex;
  final String userName;
  final Set<String> selectedKeys;
  final bool isSubmitting;
  final String? errorMessage;

  bool get hasValidName => userName.trim().length >= 2;

  OnboardingState copyWith({
    int? pageIndex,
    String? userName,
    Set<String>? selectedKeys,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingState(
      pageIndex: pageIndex ?? this.pageIndex,
      userName: userName ?? this.userName,
      selectedKeys: selectedKeys ?? this.selectedKeys,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [pageIndex, userName, selectedKeys, isSubmitting, errorMessage];
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required SeedStarterHabits seedStarterHabits,
    required SettingsRepository settingsRepository,
  })  : _seedStarterHabits = seedStarterHabits,
        _settingsRepository = settingsRepository,
        super(const OnboardingState()) {
    on<OnboardingPageChanged>((e, emit) {
      emit(state.copyWith(pageIndex: e.index));
    });
    on<OnboardingNameChanged>((e, emit) {
      emit(state.copyWith(userName: e.name, clearError: true));
    });
    on<OnboardingToggleStarter>(_onToggle);
    on<OnboardingCompleted>(_onComplete);
  }

  final SeedStarterHabits _seedStarterHabits;
  final SettingsRepository _settingsRepository;
  final _uuid = const Uuid();

  static const starters =
      <String, ({String name, String description, int icon, int color})>{
    'read': (
      name: 'Reading',
      description: 'Read 20 pages',
      icon: 0xe0ef,
      color: 0xFFFFF1C2,
    ),
    'workout': (
      name: 'Workout',
      description: 'Move for 30 min',
      icon: 0xe29d,
      color: 0xFFE2F6D5,
    ),
    'meditate': (
      name: 'Meditate',
      description: 'Breathe for 10 min',
      icon: 0xf06f,
      color: 0xFFD6ECFF,
    ),
    'water': (
      name: 'Hydrate',
      description: 'Drink 8 glasses',
      icon: 0xe798,
      color: 0xFFD6ECFF,
    ),
    'sleep': (
      name: 'Sleep early',
      description: 'In bed by 11pm',
      icon: 0xe3a9,
      color: 0xFFFFD6E7,
    ),
  };

  void _onToggle(OnboardingToggleStarter event, Emitter<OnboardingState> emit) {
    final next = Set<String>.from(state.selectedKeys);
    if (next.contains(event.key)) {
      if (next.length > 1) next.remove(event.key);
    } else if (next.length < 5) {
      next.add(event.key);
    }
    emit(state.copyWith(selectedKeys: next));
  }

  Future<void> _onComplete(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.hasValidName) {
      emit(
        state.copyWith(
          pageIndex: 1,
          errorMessage: 'Come on, even your plants have names. Drop one in.',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final now = DateTime.now();
      final habits = state.selectedKeys.map((key) {
        final starter = starters[key]!;
        final icon = switch (key) {
          'read' => HabitPalette.icons[0].codePoint,
          'workout' => HabitPalette.icons[1].codePoint,
          'meditate' => HabitPalette.icons[2].codePoint,
          'water' => HabitPalette.icons[3].codePoint,
          _ => HabitPalette.icons[4].codePoint,
        };
        return Habit(
          id: _uuid.v4(),
          name: starter.name,
          description: starter.description,
          iconCode: icon,
          colorValue: starter.color,
          frequency: 'daily',
          archived: false,
          createdAt: now,
        );
      }).toList();

      await _seedStarterHabits(habits);
      await _settingsRepository.setUserName(state.userName);
      await _settingsRepository.setOnboardingComplete(true);
      emit(state.copyWith(isSubmitting: false, clearError: true));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Could not finish setup. Try again.',
        ),
      );
    }
  }
}
