import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dummy_data/dummy_workout_plans.dart';

class WorkoutNotifier extends StateNotifier<List<MemberWorkoutPlan>> {
  WorkoutNotifier() : super(dummyWorkoutPlans);

  void addPlan(MemberWorkoutPlan plan) {
    // If a plan already exists for this member, replace it
    final existingIndex = state.indexWhere((p) => p.memberId == plan.memberId);
    if (existingIndex >= 0) {
      final updated = List<MemberWorkoutPlan>.from(state);
      updated[existingIndex] = plan;
      state = updated;
    } else {
      state = [...state, plan];
    }
  }

  MemberWorkoutPlan? getPlanForMember(String memberId) {
    final index = state.indexWhere((p) => p.memberId == memberId);
    if (index >= 0) return state[index];
    return null;
  }
}

final workoutPlansProvider =
    StateNotifierProvider<WorkoutNotifier, List<MemberWorkoutPlan>>((ref) {
  return WorkoutNotifier();
});
