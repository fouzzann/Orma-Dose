import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/models/history_log.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final logs = appState.activeHistoryLogs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adherence Stats
    int totalLogged = logs.length;
    int takenCount = logs.where((l) => l.status == 'taken').length;
    int skippedCount = logs.where((l) => l.status == 'skipped').length;
    int missedCount = logs.where((l) => l.status == 'missed').length;

    double adherenceRate = totalLogged == 0 ? 1.0 : (takenCount / (totalLogged - skippedCount));
    if (adherenceRate.isNaN || adherenceRate.isInfinite) adherenceRate = 1.0;
    
    // Sort logs descending for timeline
    final sortedLogs = List<HistoryLog>.from(logs);
    sortedLogs.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    // Calculate past 7 days data for FLChart
    final now = DateTime.now();
    final List<double> dailyAdherence = [];
    final List<String> dayLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final dayLogs = logs.where((l) {
        return DateFormat('yyyy-MM-dd').format(l.scheduledTime) == dateStr;
      }).toList();

      if (dayLogs.isEmpty) {
        dailyAdherence.add(100.0); // 100% as default
      } else {
        final taken = dayLogs.where((l) => l.status == 'taken').length;
        final total = dayLogs.length;
        dailyAdherence.add((taken / total) * 100.0);
      }
      dayLabels.add(DateFormat('E').format(date));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "History & Insights",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 20),

              // Compliance Stats Summary Cards
              _buildStatsSummary(context, adherenceRate, takenCount, missedCount, appState.streak, isDark),
              const SizedBox(height: 24),

              // Interactive Chart
              Text("Weekly Compliance Report", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildComplianceChart(context, dailyAdherence, dayLabels, isDark),
              const SizedBox(height: 24),

              // Badges & Achievements
              Text("Achievements & Badges", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildAchievementsSection(context, adherenceRate, appState.streak, isDark),
              const SizedBox(height: 24),

              // Log Timeline list
              Text("Medication Logs", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (sortedLogs.isEmpty)
                _buildEmptyState(context, isDark)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedLogs.length.clamp(0, 15), // Show recent 15 logs
                  itemBuilder: (context, index) {
                    final log = sortedLogs[index];
                    return _buildLogItem(context, log, isDark);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(
    BuildContext context, 
    double rate, 
    int taken, 
    int missed, 
    int streak,
    bool isDark,
  ) {
    final ratePercent = (rate * 100).round();
    
    return Row(
      children: [
        // Adherence Rate Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                  radius: 18,
                  child: const Icon(Icons.favorite_rounded, color: AppTheme.primaryTeal, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  "$ratePercent%",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text("Adherence Score", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Taken / Missed Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
                  radius: 18,
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  "$taken taken",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text("$missed missed total", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.withOpacity(0.1),
                  radius: 18,
                  child: const Text("🔥", style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 12),
                Text(
                  "$streak days",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text("Perfect Streak", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceChart(BuildContext context, List<double> adherence, List<String> labels, bool isDark) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? Colors.blueGrey[900]! : Colors.blueGrey[50]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "${rod.toY.round()}%",
                  TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: adherence[index],
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.primaryBlue],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, double rate, int streak, bool isDark) {
    // Achievements list
    final List<Map<String, dynamic>> badges = [
      {
        'title': 'Dose Master',
        'desc': 'Logged first taken medication.',
        'icon': '💊',
        'unlocked': rate > 0.0,
      },
      {
        'title': 'Streak Starter',
        'desc': 'Reached 3 day streak.',
        'icon': '🔥',
        'unlocked': streak >= 3,
      },
      {
        'title': 'Consistency Champ',
        'desc': 'Maintained >90% adherence.',
        'icon': '🏆',
        'unlocked': rate >= 0.90,
      },
      {
        'title': 'Pill Guardian',
        'desc': 'Reached 10 day streak.',
        'icon': '🛡️',
        'unlocked': streak >= 10,
      },
    ];

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final unlocked = badge['unlocked'] as bool;
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: unlocked 
                    ? AppTheme.primaryTeal.withOpacity(0.4) 
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: unlocked 
                      ? AppTheme.primaryTeal.withOpacity(0.12) 
                      : Colors.grey.withOpacity(0.1),
                  child: Text(
                    badge['icon'],
                    style: TextStyle(
                      fontSize: 18,
                      color: unlocked ? null : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        badge['title'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: unlocked ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge['desc'],
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
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

  Widget _buildLogItem(BuildContext context, HistoryLog log, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'taken':
        statusColor = AppTheme.accentGreen;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'skipped':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle_rounded;
        break;
      default:
        statusColor = AppTheme.alertRed;
        statusIcon = Icons.cancel_rounded;
    }

    final dateStr = DateFormat('EEE, MMM dd').format(log.scheduledTime);
    final timeStr = DateFormat('hh:mm a').format(log.scheduledTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicineName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  "${log.dosage} • Scheduled: $timeStr",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                log.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: isDark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No logs recorded yet.",
              style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }
}
