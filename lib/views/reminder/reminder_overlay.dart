import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';

class ReminderOverlay extends StatefulWidget {
  final ReminderData reminderData;

  const ReminderOverlay({
    super.key,
    required this.reminderData,
  });

  @override
  State<ReminderOverlay> createState() => _ReminderOverlayState();
}

class _ReminderOverlayState extends State<ReminderOverlay> {
  bool _isVoicePlaying = true;
  late Timer _waveTimer;
  List<double> _waveHeights = [10, 20, 30, 20, 10];

  @override
  void initState() {
    super.initState();
    // Simulate voice speech waves bouncing
    _waveTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_isVoicePlaying) {
        setState(() {
          _waveHeights = List.generate(7, (index) => 10.0 + (index % 2 == 0 ? 10.0 : 35.0) * (0.4 + 0.6 * (index % 3 == 0 ? 0.3 : 0.9)));
        });
      }
    });
  }

  @override
  void dispose() {
    _waveTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final med = widget.reminderData.medicine;
    final timeStr = widget.reminderData.time;
    final dateVal = widget.reminderData.date;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find profile name
    final member = appState.familyMembers.firstWhere(
      (m) => m.id == med.familyMemberId,
      orElse: () => appState.familyMembers.first,
    );

    IconData medIcon = Icons.adjust_rounded;
    switch (med.type) {
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
      color: Colors.black.withOpacity(0.9), // Dark dim background
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              // Top Banner Alert
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_on_rounded, color: AppTheme.alertOrange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "MEDICATION DUE NOW",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.alertOrange,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Spacer(),

              // Medicine Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Member tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "For: ${member.name}",
                        style: const TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pulse Icon
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                      child: Icon(medIcon, color: AppTheme.primaryTeal, size: 36),
                    ),
                    const SizedBox(height: 18),

                    // Med Details
                    Text(
                      med.name,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      med.dosage,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Scheduled for $timeStr",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Voice synthesizer simulation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isVoicePlaying = !_isVoicePlaying;
                            });
                          },
                          icon: Icon(
                            _isVoicePlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          "Voice Reminder Speaking...",
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Equalizer wave simulation
                    SizedBox(
                      height: 40,
                      width: 140,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_waveHeights.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 6,
                            height: _isVoicePlaying ? _waveHeights[index] : 4.0,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Accessible Action Button Layout
              Column(
                children: [
                  // Take Now - Massive Green Button (Elder friendly, minimum height 64px)
                  ElevatedButton(
                    onPressed: () {
                      appState.takeMedicine(med, timeStr, dateVal);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Dose recorded! Good job, ${member.name}."),
                          backgroundColor: AppTheme.accentGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 24),
                        SizedBox(width: 10),
                        Text(
                          "TAKE NOW",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Skip and Snooze Row
                  Row(
                    children: [
                      // Skip Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            appState.skipMedicine(med, timeStr, dateVal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Dose skipped."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            foregroundColor: Colors.white70,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("Skip Dose", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Snooze Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            appState.dismissReminder();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Snoozed alert for 15 minutes."),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text("Snooze 15m", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
