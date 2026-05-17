import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../workout/providers/workout_provider.dart';
import '../../../dummy_data/dummy_workout_plans.dart';

class MemberClassesScreen extends ConsumerStatefulWidget {
  const MemberClassesScreen({super.key});

  @override
  ConsumerState<MemberClassesScreen> createState() => _MemberClassesScreenState();
}

class _MemberClassesScreenState extends ConsumerState<MemberClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);

    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Activity', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Attendance Log'),
            Tab(text: 'My Workout'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AttendanceLogTab(memberId: member.id, memberName: member.name),
          _MyWorkoutTab(memberId: member.id, memberName: member.name),
        ],
      ),
    );
  }
}

class _AttendanceLogTab extends ConsumerWidget {
  final String memberId;
  final String memberName;

  const _AttendanceLogTab({required this.memberId, required this.memberName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);
    final memberRecords = attendanceState.allRecords
        .where((r) => r.memberId == memberId || r.memberName == memberName)
        .toList();

    memberRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final now = DateTime.now();
    final presentDates = memberRecords.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();

    // Current month calculations
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int presentCount = 0;
    int absentCount = 0;

    for (int day = 1; day <= now.day; day++) {
      final d = DateTime(now.year, now.month, day);
      if (d.weekday == DateTime.sunday) continue; // skip sundays as working days
      if (presentDates.contains(d)) {
        presentCount++;
      } else {
        absentCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Total Present", style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text("$presentCount days", style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 24)),
                  ],
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                Column(
                  children: [
                    Text("Total Absent", style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text("$absentCount days", style: AppTextStyles.heading1.copyWith(color: Colors.redAccent, fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Calendar Grid
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(now),
                    style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((w) => Text(w, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 13))).toList(),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: daysInMonth + (firstDayOfMonth.weekday - 1),
                    itemBuilder: (context, index) {
                      final offset = firstDayOfMonth.weekday - 1;
                      if (index < offset) return const SizedBox.shrink();
                      final dayNumber = index - offset + 1;
                      final date = DateTime(now.year, now.month, dayNumber);
                      final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
                      final isToday = date.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
                      final isSunday = date.weekday == DateTime.sunday;
                      final isPresent = presentDates.contains(date);

                      Color bg = Colors.transparent;
                      Color fg = AppColors.textPrimary;
                      Border? border;

                      if (isToday) {
                        border = Border.all(color: AppColors.primary, width: 2);
                      }

                      if (!isFuture && !isSunday) {
                        if (isPresent) {
                          bg = Colors.green.withValues(alpha: 0.15);
                          fg = Colors.green[800]!;
                        } else {
                          bg = Colors.red.withValues(alpha: 0.15);
                          fg = Colors.red[800]!;
                        }
                      } else if (isSunday || isFuture) {
                        fg = Colors.grey[400]!;
                      }

                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          shape: BoxShape.circle,
                          border: border,
                        ),
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 13),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Colors.green, "Present"),
                      const SizedBox(width: 20),
                      _buildLegend(Colors.red, "Absent"),
                      const SizedBox(width: 20),
                      _buildLegend(Colors.grey[400]!, "Weekend/Future"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Attendance Log History',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (memberRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No attendance records found', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...memberRecords.map((record) {
              final dateStr = DateFormat('EEE, dd MMM yyyy').format(record.checkInTime);
              final checkInStr = DateFormat('hh:mm a').format(record.checkInTime);
              final checkOutStr = record.checkOutTime != null ? DateFormat('hh:mm a').format(record.checkOutTime!) : "--";

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: record.checkOutTime == null ? AppColors.accent.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          record.checkOutTime == null ? Icons.run_circle : Icons.check_circle,
                          color: record.checkOutTime == null ? AppColors.accent : AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("Check-in: $checkInStr • Check-out: $checkOutStr", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MyWorkoutTab extends ConsumerWidget {
  final String memberId;
  final String memberName;

  const _MyWorkoutTab({required this.memberId, required this.memberName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(workoutPlansProvider);
    final plan = plans.where((p) => p.memberId == memberId || p.memberName == memberName).firstOrNull;

    return Stack(
      children: [
        if (plan == null)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyStateWidget(
                  icon: Icons.fitness_center,
                  title: 'No workout plan assigned',
                  subtitle: 'Create your custom routine or request one from your trainer.',
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: "Create Custom Routine",
                  onPressed: () => _openCreateRoutineModal(context, ref, memberId, memberName),
                ),
              ],
            ),
          )
        else
          ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getGoalBadge(plan.goal),
                      style: const TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (plan.isCreatedByMember)
                    Chip(
                      label: const Text("Created by Member", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(plan.planName, style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              ...plan.days.map((day) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  child: ExpansionTile(
                    title: Text(day.dayLabel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    children: day.exercises.map((ex) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fitness_center, size: 18, color: AppColors.primary),
                        ),
                        title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "${ex.sets} sets × ${ex.reps} reps • Rest: ${ex.restSeconds}s${ex.notes != null ? '\nNotes: ${ex.notes}' : ''}",
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                        isThreeLine: ex.notes != null,
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit),
            label: const Text("Create Custom Routine"),
            onPressed: () => _openCreateRoutineModal(context, ref, memberId, memberName),
          ),
        ),
      ],
    );
  }

  String _getGoalBadge(String goal) {
    if (goal == 'muscle_gain') return "💪 Muscle Gain";
    if (goal == 'weight_loss') return "🔥 Weight Loss";
    return "🎯 General Fitness";
  }

  void _openCreateRoutineModal(BuildContext context, WidgetRef ref, String memberId, String memberName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _CreateWorkoutModal(memberId: memberId, memberName: memberName, onSave: (newPlan) {
        ref.read(workoutPlansProvider.notifier).addPlan(newPlan);
        SnackbarHelper.showSuccess(context, "Workout routine saved successfully ✓");
      }),
    );
  }
}

class _CreateWorkoutModal extends StatefulWidget {
  final String memberId;
  final String memberName;
  final Function(MemberWorkoutPlan) onSave;

  const _CreateWorkoutModal({required this.memberId, required this.memberName, required this.onSave});

  @override
  State<_CreateWorkoutModal> createState() => _CreateWorkoutModalState();
}

class _EditableExercise {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController setsCtrl = TextEditingController(text: "3");
  final TextEditingController repsCtrl = TextEditingController(text: "12");
  final TextEditingController restCtrl = TextEditingController(text: "60");

  void dispose() {
    nameCtrl.dispose();
    setsCtrl.dispose();
    repsCtrl.dispose();
    restCtrl.dispose();
  }
}

class _EditableDay {
  final TextEditingController labelCtrl = TextEditingController();
  final List<_EditableExercise> exercises = [];

  _EditableDay(String label) {
    labelCtrl.text = label;
  }

  void dispose() {
    labelCtrl.dispose();
    for (var ex in exercises) {
      ex.dispose();
    }
  }
}

class _CreateWorkoutModalState extends State<_CreateWorkoutModal> {
  final _planNameCtrl = TextEditingController(text: "My Personal Routine");
  String _selectedGoal = "muscle_gain";
  final List<_EditableDay> _days = [];

  @override
  void initState() {
    super.initState();
    // Default 1 day with 1 exercise
    final d1 = _EditableDay("Day 1: Chest & Triceps");
    d1.exercises.add(_EditableExercise()..nameCtrl.text = "Bench Press");
    _days.add(d1);
  }

  @override
  void dispose() {
    _planNameCtrl.dispose();
    for (var d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_planNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a routine name")));
      return;
    }

    final List<WorkoutDay> finalDays = [];
    for (var d in _days) {
      if (d.labelCtrl.text.trim().isEmpty) continue;
      final List<WorkoutExercise> finalExs = [];
      for (var ex in d.exercises) {
        if (ex.nameCtrl.text.trim().isEmpty) continue;
        finalExs.add(WorkoutExercise(
          name: ex.nameCtrl.text.trim(),
          sets: int.tryParse(ex.setsCtrl.text) ?? 3,
          reps: int.tryParse(ex.repsCtrl.text) ?? 12,
          restSeconds: int.tryParse(ex.restCtrl.text) ?? 60,
        ));
      }
      if (finalExs.isNotEmpty) {
        finalDays.add(WorkoutDay(dayLabel: d.labelCtrl.text.trim(), exercises: finalExs));
      }
    }

    if (finalDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one exercise")));
      return;
    }

    final newPlan = MemberWorkoutPlan(
      id: UniqueKey().toString(),
      memberId: widget.memberId,
      memberName: widget.memberName,
      planName: _planNameCtrl.text.trim(),
      createdAt: DateTime.now(),
      goal: _selectedGoal,
      days: finalDays,
      isCreatedByMember: true,
    );

    widget.onSave(newPlan);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Create Custom Routine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _planNameCtrl,
              decoration: InputDecoration(
                labelText: "Routine Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGoal,
              decoration: InputDecoration(
                labelText: "Fitness Goal",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: "muscle_gain", child: Text("Muscle Gain")),
                DropdownMenuItem(value: "weight_loss", child: Text("Weight Loss")),
                DropdownMenuItem(value: "general_fitness", child: Text("General Fitness")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedGoal = val);
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Workout Days", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Day"),
                  onPressed: () {
                    setState(() {
                      _days.add(_EditableDay("Day ${_days.length + 1}: "));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, dIndex) {
                  final d = _days[dIndex];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: d.labelCtrl,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(labelText: "Day Title (e.g. Day 1: Pull)", isDense: true),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    d.dispose();
                                    _days.removeAt(dIndex);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...d.exercises.asMap().entries.map((entry) {
                            final exIndex = entry.key;
                            final ex = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: ex.nameCtrl,
                                      decoration: const InputDecoration(hintText: "Exercise Name", isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: ex.setsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: "Sets", isDense: true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: ex.repsCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: "Reps", isDense: true),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        ex.dispose();
                                        d.exercises.removeAt(exIndex);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Exercise"),
                            onPressed: () {
                              setState(() {
                                d.exercises.add(_EditableExercise());
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text("Save Workout Routine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
