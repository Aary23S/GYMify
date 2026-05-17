import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/classes_provider.dart';

class MemberClassesScreen extends ConsumerStatefulWidget {
  const MemberClassesScreen({super.key});

  @override
  ConsumerState<MemberClassesScreen> createState() => _MemberClassesScreenState();
}

class _MemberClassesScreenState extends ConsumerState<MemberClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDay;
  String _selectedCategory = 'All';
  String _bookingFilter = 'Upcoming'; // 'Upcoming', 'Past', 'Cancelled'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
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
    final allClasses = ref.watch(classesProvider);

    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classes & Booking', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Available Classes'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableTab(allClasses, member.id),
          _buildMyBookingsTab(allClasses, member.id),
        ],
      ),
    );
  }

  Widget _buildAvailableTab(List<GymClassSession> allClasses, String memberId) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    // Filter classes for selected day & category
    final dayClasses = allClasses.where((c) {
      final cDateOnly = DateTime(c.date.year, c.date.month, c.date.day);
      if (!cDateOnly.isAtSameMomentAs(_selectedDay)) return false;
      if (_selectedCategory != 'All' && c.category != _selectedCategory) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Horizontal Day Selector
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final date = todayOnly.add(Duration(days: index));
                final isSelected = date.isAtSameMomentAs(_selectedDay);
                final dayStr = DateFormat('EEE').format(date).toUpperCase();

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(dayStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(date.day.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? Colors.white : AppColors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // Filter Chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Zumba', 'Yoga', 'HIIT', 'Spinning', 'CrossFit'].map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    backgroundColor: Colors.grey[100],
                    selectedColor: AppColors.accent,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppColors.accent : AppColors.border)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        // Class Cards List
        Expanded(
          child: dayClasses.isEmpty
              ? Center(child: Text("No classes found for ${_selectedCategory == 'All' ? 'this day' : _selectedCategory}", style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayClasses.length,
                  itemBuilder: (context, index) {
                    final c = dayClasses[index];
                    final isBooked = c.isBookedBy(memberId);
                    final isFull = c.isFull && !isBooked;

                    Color typeBg;
                    switch (c.category) {
                      case 'Yoga': typeBg = Colors.teal; break;
                      case 'HIIT': typeBg = Colors.orange; break;
                      case 'Zumba': typeBg = Colors.pink; break;
                      case 'CrossFit': typeBg = Colors.red[700]!; break;
                      default: typeBg = Colors.blue; break;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border(left: BorderSide(color: typeBg, width: 6)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(c.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: typeBg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: typeBg.withValues(alpha: 0.3))),
                                        child: Text(c.category, style: TextStyle(color: typeBg, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Text("${c.startTime} – ${c.endTime}", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CircleAvatar(radius: 10, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, size: 12, color: AppColors.primary)),
                                      const SizedBox(width: 6),
                                      Text(c.trainerName, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text("${c.bookedMemberIds.length}/${c.maxSpots} spots", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Trailing Button or Status Badge
                            if (isBooked)
                              Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                  const SizedBox(height: 4),
                                  Text("Booked", style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              )
                            else if (isFull)
                              Column(
                                children: [
                                  Text("Full", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text("${c.maxSpots}/${c.maxSpots}", style: TextStyle(color: Colors.red[800], fontSize: 11)),
                                ],
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showBookDialog(context, c, memberId),
                                child: const Text("Book", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBookDialog(BuildContext context, GymClassSession c, String memberId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final spotsLeft = c.maxSpots - c.bookedMemberIds.length;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Confirm Booking", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.className, style: AppTextStyles.heading3.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(DateFormat('EEEE, dd MMM yyyy').format(c.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text("${c.startTime} – ${c.endTime}", style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(c.trainerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(c.location, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("Spots remaining: $spotsLeft/${c.maxSpots}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
              onPressed: () {
                ref.read(classesProvider.notifier).bookClass(c.id, memberId);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✓ Booked ${c.className} for ${DateFormat('dd MMM').format(c.date)}"), backgroundColor: Colors.green));
              },
              child: const Text("Confirm Booking"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyBookingsTab(List<GymClassSession> allClasses, String memberId) {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    final memberBookings = allClasses.where((c) => c.isBookedBy(memberId)).toList();
    memberBookings.sort((a, b) => b.date.compareTo(a.date));

    final filtered = memberBookings.where((c) {
      final cDateOnly = DateTime(c.date.year, c.date.month, c.date.day);
      if (_bookingFilter == 'Upcoming') {
        return cDateOnly.isAfter(todayOnly) || cDateOnly.isAtSameMomentAs(todayOnly);
      } else {
        return cDateOnly.isBefore(todayOnly);
      }
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: ['Upcoming', 'Past'].map((filt) {
              final isSel = _bookingFilter == filt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filt, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  selected: isSel,
                  onSelected: (_) => setState(() => _bookingFilter = filt),
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text("No $_bookingFilter bookings found", style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final dayStr = DateFormat('EEE').format(c.date).toUpperCase();
                    final numStr = DateFormat('dd').format(c.date);
                    final isUpcoming = _bookingFilter == 'Upcoming';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Text(dayStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[500])),
                                const SizedBox(height: 2),
                                Text(numStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Container(width: 1, height: 40, color: AppColors.border),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text("${c.startTime} · ${c.trainerName}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isUpcoming) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text("Upcoming", style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Cancel Booking"),
                                      content: Text("Are you sure you want to cancel your booking for ${c.className}?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () {
                                            ref.read(classesProvider.notifier).cancelBooking(c.id, memberId);
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cancelled ${c.className}"), backgroundColor: Colors.red));
                                          },
                                          child: const Text("Yes, Cancel"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text("Attended ✓", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
