import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/models/medicine.dart';
import 'package:orma_dose/views/medicines/add_medicine_view.dart';

class ScheduledSlot {
  final Medicine medicine;
  final String time; // "08:00"
  final DateTime dateTime;

  ScheduledSlot({
    required this.medicine,
    required this.time,
    required this.dateTime,
  });
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  List<ScheduledSlot> _getTodaySchedule(List<Medicine> medicines) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday; // 1 = Mon, 7 = Sun
    final List<ScheduledSlot> slots = [];

    for (var med in medicines) {
      // Check date range
      final startOnlyDate = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endOnlyDate = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      if (todayStart.isBefore(startOnlyDate) || todayStart.isAfter(endOnlyDate)) {
        continue;
      }

      // Check frequency
      bool isScheduledToday = false;
      if (med.frequencyType == 'daily') {
        isScheduledToday = true;
      } else if (med.frequencyType == 'weekly') {
        isScheduledToday = med.selectedDays.contains(weekday);
      }

      if (isScheduledToday) {
        for (var timeStr in med.reminderTimes) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final min = int.parse(parts[1]);
          final slotDateTime = DateTime(now.year, now.month, now.day, hour, min);
          slots.add(ScheduledSlot(
            medicine: med,
            time: timeStr,
            dateTime: slotDateTime,
          ));
        }
      }
    }

    // Sort chronologically
    slots.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final activeMember = appState.activeProfile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final todaySlots = _getTodaySchedule(appState.activeMedicines);

    // Calculate adherence stats
    int totalToday = todaySlots.length;
    int takenToday = 0;
    int skippedToday = 0;
    int missedToday = 0;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (var slot in todaySlots) {
      final logId = 'log_${slot.medicine.id}_${todayStr}_${slot.time.replaceAll(':', '')}';
      final logIndex = appState.historyLogs.indexWhere((l) => l.id == logId);
      if (logIndex != -1) {
        final status = appState.historyLogs[logIndex].status;
        if (status == 'taken') takenToday++;
        if (status == 'skipped') skippedToday++;
        if (status == 'missed') missedToday++;
      }
    }

    final pendingToday = totalToday - takenToday - skippedToday - missedToday;
    final adherenceRate = totalToday == 0 ? 1.0 : (takenToday / totalToday);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context, appState, activeMember),
              const SizedBox(height: 24),

              // Progress Card
              _buildProgressCard(context, totalToday, takenToday, adherenceRate, pendingToday, isDark),
              const SizedBox(height: 24),

              // Stock Alert warnings
              _buildRefillWarnings(context, appState),

              // Schedule Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Schedule",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMedicineView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add New"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Timeline List
              if (totalToday == 0)
                _buildEmptyState(context, isDark)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaySlots.length,
                  itemBuilder: (context, index) {
                    final slot = todaySlots[index];
                    return _buildTimelineItem(context, appState, slot, todayStr, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStateProvider appState, dynamic activeMember) {
    if (activeMember == null) return const SizedBox.shrink();

    // Determine greeting
    final hour = DateTime.now().hour;
    String greeting = "Good Morning";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else if (hour >= 17) {
      greeting = "Good Evening";
    }

    final avatars = [
      Icons.sentiment_satisfied_alt_rounded,
      Icons.face_3_rounded,
      Icons.face_6_rounded,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "$greeting, ",
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppTheme.textMutedDark 
                          : AppTheme.textMutedLight,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      activeMember.name.split(' ').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Orma Dose",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Family Switcher Icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streak counter
            if (appState.streak > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      "${appState.streak}d",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            // Profile circles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: appState.familyMembers.map((member) {
                final isSelected = member.id == appState.activeProfileId;
                final avatarIcon = avatars[member.avatarIndex % avatars.length];
                
                return GestureDetector(
                  onTap: () => appState.setActiveProfile(member.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected 
                          ? AppTheme.primaryTeal.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.15),
                      child: Icon(
                        avatarIcon,
                        size: 14,
                        color: isSelected 
                            ? AppTheme.primaryTeal 
                            : Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context, 
    int totalToday, 
    int takenToday, 
    double adherenceRate, 
    int pendingToday,
    bool isDark,
  ) {
    final percentVal = (adherenceRate * 100).round();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Adherence Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.2)),
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: adherenceRate,
                  strokeWidth: 8,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.transparent,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$percentVal%",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Taken",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Progress text
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Today's Progress",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  totalToday == 0
                      ? "No medications scheduled for today."
                      : "$takenToday of $totalToday doses taken.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                if (totalToday > 0 && pendingToday > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$pendingToday remaining",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (totalToday > 0 && pendingToday == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          "Completed!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefillWarnings(BuildContext context, AppStateProvider appState) {
    final lowStockMeds = appState.activeMedicines
        .where((m) => m.remainingStock <= m.refillThreshold)
        .toList();

    if (lowStockMeds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lowStockMeds.map((med) {
          final isSyrup = med.type == 'syrup';
          final unit = isSyrup ? 'ml' : 'pills';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.alertOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.alertOrange.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.alertOrange,
                  radius: 18,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Refill Warning",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.alertOrange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${med.name} running low: ${med.remainingStock}$unit left.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[300] 
                              : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    appState.refillMedicine(med.id, isSyrup ? 150 : 30);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Refilled ${med.name}! +${isSyrup ? '150ml' : '30 pills'} added."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.alertOrange,
                    minimumSize: const Size(64, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Refill", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, 
    AppStateProvider appState, 
    ScheduledSlot slot, 
    String todayStr,
    bool isDark,
  ) {
    final logId = 'log_${slot.medicine.id}_${todayStr}_${slot.time.replaceAll(':', '')}';
    final logIndex = appState.historyLogs.indexWhere((l) => l.id == logId);
    
    String status = 'pending';
    if (logIndex != -1) {
      status = appState.historyLogs[logIndex].status;
    } else {
      // If time passed by more than 1 hour and not logged, it's missed
      final parts = slot.time.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      final limitTime = DateTime.now().subtract(const Duration(hours: 1));
      final slotDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        hour,
        min,
      );
      if (slotDateTime.isBefore(limitTime)) {
        status = 'missed';
      }
    }

    // Colors mapping
    Color cardColor;
    Color iconBgColor;
    IconData statusIcon;
    Color statusColor;
    String statusLabel = '';

    switch (status) {
      case 'taken':
        cardColor = AppTheme.accentGreen.withOpacity(0.08);
        iconBgColor = AppTheme.accentGreen;
        statusIcon = Icons.check_rounded;
        statusColor = AppTheme.accentGreen;
        statusLabel = 'Taken';
        break;
      case 'skipped':
        cardColor = isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.08);
        iconBgColor = Colors.grey;
        statusIcon = Icons.remove_rounded;
        statusColor = Colors.grey;
        statusLabel = 'Skipped';
        break;
      case 'missed':
        cardColor = AppTheme.alertRed.withOpacity(0.08);
        iconBgColor = AppTheme.alertRed;
        statusIcon = Icons.close_rounded;
        statusColor = AppTheme.alertRed;
        statusLabel = 'Missed';
        break;
      default:
        cardColor = isDark ? AppTheme.cardDark : AppTheme.cardLight;
        iconBgColor = AppTheme.primaryTeal.withOpacity(0.1);
        statusIcon = Icons.schedule_rounded;
        statusColor = AppTheme.primaryTeal;
        statusLabel = slot.time;
    }

    // Medicine type icons
    IconData medIcon = Icons.circle;
    switch (slot.medicine.type) {
      case 'tablet':
        medIcon = Icons.adjust_rounded;
        break;
      case 'capsule':
        medIcon = Icons.egg_alt_rounded;
        break;
      case 'syrup':
        medIcon = Icons.vaccines_rounded;
        break;
      case 'injection':
        medIcon = Icons.colorize_rounded;
        break;
      case 'drops':
        medIcon = Icons.water_drop_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: status == 'pending' 
              ? (isDark ? AppTheme.borderDark : AppTheme.borderLight) 
              : statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.time,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getTimePeriodLabel(slot.time),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Vertical line divider
          Container(
            height: 40,
            width: 1.5,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
          const SizedBox(width: 16),
          // Med Icon
          CircleAvatar(
            radius: 20,
            backgroundColor: status == 'pending' ? iconBgColor : iconBgColor.withOpacity(0.15),
            child: Icon(
              medIcon,
              color: status == 'pending' ? AppTheme.primaryTeal : iconBgColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Medicine name & dose details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.medicine.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slot.medicine.dosage,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          // Action button / status tag
          if (status == 'pending' || status == 'missed')
            Row(
              children: [
                // Skip Button
                IconButton(
                  onPressed: () {
                    appState.skipMedicine(slot.medicine, slot.time, slot.dateTime);
                  },
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  tooltip: 'Skip dose',
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
                // Take Button
                ElevatedButton(
                  onPressed: () {
                    appState.takeMedicine(slot.medicine, slot.time, slot.dateTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    minimumSize: const Size(60, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Take",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getTimePeriodLabel(String timeStr) {
    final hour = int.parse(timeStr.split(':')[0]);
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            child: const Icon(
              Icons.done_all_rounded,
              color: AppTheme.primaryTeal,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "All Clear!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No medications scheduled for today. Relax and enjoy your day!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
