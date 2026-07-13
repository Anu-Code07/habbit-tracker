import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:pulse/features/habits/domain/entities/habit.dart';
import 'package:pulse/features/habits/domain/usecases/habit_usecases.dart';

sealed class HabitsEvent extends Equatable {
  const HabitsEvent();
  @override
  List<Object?> get props => [];
}

class HabitsStarted extends HabitsEvent {
  const HabitsStarted();
}

class HabitCreated extends HabitsEvent {
  const HabitCreated({
    required this.name,
    required this.description,
    required this.iconCode,
    required this.colorValue,
    required this.frequency,
  });

  final String name;
  final String description;
  final int iconCode;
  final int colorValue;
  final String frequency;

  @override
  List<Object?> get props => [name, description, iconCode, colorValue, frequency];
}

class HabitUpdated extends HabitsEvent {
  const HabitUpdated(this.habit);
  final Habit habit;
  @override
  List<Object?> get props => [habit];
}

class HabitArchived extends HabitsEvent {
  const HabitArchived(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

sealed class HabitsState extends Equatable {
  const HabitsState();
  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {
  const HabitsInitial();
}

class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

class HabitsSuccess extends HabitsState {
  const HabitsSuccess(this.habits);
  final List<Habit> habits;
  @override
  List<Object?> get props => [habits];
}

class HabitsEmpty extends HabitsState {
  const HabitsEmpty();
}

class HabitsError extends HabitsState {
  const HabitsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  HabitsBloc({
    required GetActiveHabits getActiveHabits,
    required CreateHabit createHabit,
    required UpdateHabit updateHabit,
    required ArchiveHabit archiveHabit,
  })  : _getActiveHabits = getActiveHabits,
        _createHabit = createHabit,
        _updateHabit = updateHabit,
        _archiveHabit = archiveHabit,
        super(const HabitsInitial()) {
    on<HabitsStarted>(_load);
    on<HabitCreated>(_onCreate);
    on<HabitUpdated>(_onUpdate);
    on<HabitArchived>(_onArchive);
  }

  final GetActiveHabits _getActiveHabits;
  final CreateHabit _createHabit;
  final UpdateHabit _updateHabit;
  final ArchiveHabit _archiveHabit;
  final _uuid = const Uuid();

  Future<void> _load(HabitsEvent event, Emitter<HabitsState> emit) async {
    emit(const HabitsLoading());
    try {
      final habits = await _getActiveHabits();
      emit(habits.isEmpty ? const HabitsEmpty() : HabitsSuccess(habits));
    } catch (_) {
      emit(const HabitsError('Could not load habits.'));
    }
  }

  Future<void> _onCreate(HabitCreated event, Emitter<HabitsState> emit) async {
    try {
      final habit = Habit(
        id: _uuid.v4(),
        name: event.name.trim(),
        description: event.description.trim(),
        iconCode: event.iconCode,
        colorValue: event.colorValue,
        frequency: event.frequency,
        archived: false,
        createdAt: DateTime.now(),
      );
      await _createHabit(habit);
      final habits = await _getActiveHabits();
      emit(habits.isEmpty ? const HabitsEmpty() : HabitsSuccess(habits));
    } catch (_) {
      emit(const HabitsError('Could not create habit.'));
    }
  }

  Future<void> _onUpdate(HabitUpdated event, Emitter<HabitsState> emit) async {
    try {
      await _updateHabit(event.habit);
      final habits = await _getActiveHabits();
      emit(habits.isEmpty ? const HabitsEmpty() : HabitsSuccess(habits));
    } catch (_) {
      emit(const HabitsError('Could not update habit.'));
    }
  }

  Future<void> _onArchive(
    HabitArchived event,
    Emitter<HabitsState> emit,
  ) async {
    try {
      await _archiveHabit(event.id);
      final habits = await _getActiveHabits();
      emit(habits.isEmpty ? const HabitsEmpty() : HabitsSuccess(habits));
    } catch (_) {
      emit(const HabitsError('Could not archive habit.'));
    }
  }
}
