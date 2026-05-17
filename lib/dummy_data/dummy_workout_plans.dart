class WorkoutExercise {
  final String name;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;

  const WorkoutExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
  });

  WorkoutExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }
}

class WorkoutDay {
  final String dayLabel;
  final List<WorkoutExercise> exercises;

  const WorkoutDay({
    required this.dayLabel,
    required this.exercises,
  });

  WorkoutDay copyWith({
    String? dayLabel,
    List<WorkoutExercise>? exercises,
  }) {
    return WorkoutDay(
      dayLabel: dayLabel ?? this.dayLabel,
      exercises: exercises ?? this.exercises,
    );
  }
}

class MemberWorkoutPlan {
  final String id;
  final String memberId;
  final String memberName;
  final String planName;
  final DateTime createdAt;
  final String goal; // 'weight_loss', 'muscle_gain', 'general_fitness'
  final List<WorkoutDay> days;
  final bool isCreatedByMember;

  const MemberWorkoutPlan({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.planName,
    required this.createdAt,
    required this.goal,
    required this.days,
    required this.isCreatedByMember,
  });

  MemberWorkoutPlan copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? planName,
    DateTime? createdAt,
    String? goal,
    List<WorkoutDay>? days,
    bool? isCreatedByMember,
  }) {
    return MemberWorkoutPlan(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      planName: planName ?? this.planName,
      createdAt: createdAt ?? this.createdAt,
      goal: goal ?? this.goal,
      days: days ?? this.days,
      isCreatedByMember: isCreatedByMember ?? this.isCreatedByMember,
    );
  }
}

final List<MemberWorkoutPlan> dummyWorkoutPlans = [
  MemberWorkoutPlan(
    id: 'wp_1',
    memberId: '1',
    memberName: 'Arjun Sharma',
    planName: 'Advanced Hypertrophy Routine',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    goal: 'muscle_gain',
    isCreatedByMember: true,
    days: const [
      WorkoutDay(
        dayLabel: 'Day 1 — Chest & Triceps',
        exercises: [
          WorkoutExercise(name: 'Barbell Bench Press', sets: 4, reps: 10, restSeconds: 90, notes: 'Focus on slow negative'),
          WorkoutExercise(name: 'Incline Dumbbell Press', sets: 3, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Chest Flyes (Machine)', sets: 3, reps: 15, restSeconds: 60, notes: 'Squeeze at the top'),
          WorkoutExercise(name: 'Tricep Rope Pushdowns', sets: 4, reps: 12, restSeconds: 60),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 2 — Back & Biceps',
        exercises: [
          WorkoutExercise(name: 'Lat Pulldowns', sets: 4, reps: 12, restSeconds: 60, notes: 'Full range of motion'),
          WorkoutExercise(name: 'Barbell Rows', sets: 4, reps: 10, restSeconds: 90),
          WorkoutExercise(name: 'Seated Cable Rows', sets: 3, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Dumbbell Bicep Curls', sets: 4, reps: 12, restSeconds: 60, notes: 'Keep elbows locked in'),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 3 — Legs & Shoulders',
        exercises: [
          WorkoutExercise(name: 'Barbell Squats', sets: 4, reps: 10, restSeconds: 120, notes: 'Go parallel or deeper'),
          WorkoutExercise(name: 'Leg Press', sets: 3, reps: 12, restSeconds: 90),
          WorkoutExercise(name: 'Dumbbell Shoulder Press', sets: 4, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Lateral Raises', sets: 4, reps: 15, restSeconds: 45, notes: 'Strict form, no swinging'),
        ],
      ),
    ],
  ),
  MemberWorkoutPlan(
    id: 'wp_2',
    memberId: '2',
    memberName: 'Priya Patel',
    planName: 'HIIT Fat Shredder Routine',
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    goal: 'weight_loss',
    isCreatedByMember: true,
    days: const [
      WorkoutDay(
        dayLabel: 'Day 1 — HIIT & Core',
        exercises: [
          WorkoutExercise(name: 'Jump Squats', sets: 4, reps: 20, restSeconds: 45),
          WorkoutExercise(name: 'Mountain Climbers', sets: 4, reps: 30, restSeconds: 45, notes: 'Maintain fast pace'),
          WorkoutExercise(name: 'Plank Hold', sets: 3, reps: 60, restSeconds: 60, notes: 'Seconds hold'),
          WorkoutExercise(name: 'Bicycle Crunches', sets: 3, reps: 25, restSeconds: 45),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 2 — Upper Body Toning',
        exercises: [
          WorkoutExercise(name: 'Dumbbell Chest Press', sets: 3, reps: 15, restSeconds: 60),
          WorkoutExercise(name: 'Lat Pulldowns', sets: 3, reps: 15, restSeconds: 60),
          WorkoutExercise(name: 'Dumbbell Shoulder Press', sets: 3, reps: 15, restSeconds: 60),
          WorkoutExercise(name: 'Tricep Dips on Bench', sets: 3, reps: 15, restSeconds: 60),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 3 — Lower Body & Cardio',
        exercises: [
          WorkoutExercise(name: 'Goblet Squats', sets: 4, reps: 15, restSeconds: 60),
          WorkoutExercise(name: 'Walking Lunges', sets: 3, reps: 20, restSeconds: 60, notes: '10 per leg'),
          WorkoutExercise(name: 'Glute Bridges', sets: 4, reps: 20, restSeconds: 45, notes: 'Squeeze glutes at top'),
          WorkoutExercise(name: 'Treadmill Sprint Intervals', sets: 5, reps: 1, restSeconds: 60, notes: '1 min sprint, 1 min walk'),
        ],
      ),
    ],
  ),
  MemberWorkoutPlan(
    id: 'wp_3',
    memberId: '3',
    memberName: 'Rohan Gupta',
    planName: 'General Conditioning Split',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    goal: 'general_fitness',
    isCreatedByMember: true,
    days: const [
      WorkoutDay(
        dayLabel: 'Day 1 — Push Workout',
        exercises: [
          WorkoutExercise(name: 'Pushups', sets: 4, reps: 15, restSeconds: 60),
          WorkoutExercise(name: 'Dumbbell Bench Press', sets: 3, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Overhead Dumbbell Press', sets: 3, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Skull Crushers', sets: 3, reps: 12, restSeconds: 60),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 2 — Pull Workout',
        exercises: [
          WorkoutExercise(name: 'Pullups / Assisted Pullups', sets: 4, reps: 8, restSeconds: 90),
          WorkoutExercise(name: 'Dumbbell Rows', sets: 3, reps: 12, restSeconds: 60),
          WorkoutExercise(name: 'Face Pulls', sets: 3, reps: 15, restSeconds: 45, notes: 'Good for rear delts'),
          WorkoutExercise(name: 'Hammer Curls', sets: 3, reps: 12, restSeconds: 60),
        ],
      ),
      WorkoutDay(
        dayLabel: 'Day 3 — Full Legs & Abs',
        exercises: [
          WorkoutExercise(name: 'Dumbbell Goblet Squat', sets: 4, reps: 12, restSeconds: 90),
          WorkoutExercise(name: 'Romanian Dumbbell Deadlifts', sets: 3, reps: 12, restSeconds: 60, notes: 'Feel the hamstring stretch'),
          WorkoutExercise(name: 'Standing Calf Raises', sets: 4, reps: 20, restSeconds: 45),
          WorkoutExercise(name: 'Hanging Leg Raises', sets: 3, reps: 12, restSeconds: 60),
        ],
      ),
    ],
  ),
];
