import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final List<IconData> _avatarIcons = [
    Icons.sentiment_satisfied_alt_rounded,
    Icons.face_3_rounded,
    Icons.face_6_rounded,
    Icons.face_rounded,
    Icons.face_5_rounded,
  ];

  void _showAddMemberDialog(BuildContext context, AppStateProvider appState) {
    final nameController = TextEditingController();
    String selectedRelation = 'Parent';
    int selectedAvatar = 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Family Member"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        hintText: "e.g. Sarah Khan",
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRelation,
                      decoration: const InputDecoration(labelText: "Relationship"),
                      items: ['Parent', 'Child', 'Spouse', 'Sibling', 'Other'].map((rel) {
                        return DropdownMenuItem(value: rel, child: Text(rel));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRelation = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Select Profile Avatar", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_avatarIcons.length, (idx) {
                        final isSel = selectedAvatar == idx;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedAvatar = idx),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isSel 
                                ? AppTheme.primaryTeal 
                                : Colors.grey.withOpacity(0.15),
                            child: Icon(
                              _avatarIcons[idx],
                              color: isSel ? Colors.white : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      appState.addFamilyMember(name, selectedRelation, selectedAvatar);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$name added successfully!")),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerSimulatedScan(AppStateProvider appState) {
    // Quick scanner simulator trigger directly inside profile prescription locker
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Scan Prescription"),
          content: const Text("Simulate scanning a physical doctor slip to secure it in your prescription locker cabinet?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                
                // Add preset prescription item
                appState.uploadPrescription(
                  "Cardiac Consultation & Dosage Chart",
                  "Dr. Robert Chen, FACC",
                  ["Metformin 500mg", "Amlodipine 5mg", "Atorvastatin 20mg"],
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Prescription saved and locked securely! 🔒"),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Scan Simulator"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                "Profile & Settings",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 24),

              // Family Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Family Members", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _showAddMemberDialog(context, appState),
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFamilyProfilesList(context, appState, isDark),
              const SizedBox(height: 28),

              // Prescription Locker Cabinet Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Prescription Cabinet", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => _triggerSimulatedScan(appState),
                    icon: const Icon(Icons.document_scanner_outlined, color: AppTheme.primaryTeal, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPrescriptionLocker(context, appState, isDark),
              const SizedBox(height: 28),

              // Test Utilities Trigger (Mock alarm)
              Text("Verification Utilities", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTestUtilityCard(context, appState, isDark),
              const SizedBox(height: 28),

              // General Settings (Theme toggles)
              Text("General Preferences", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: appState.isDarkMode,
                      onChanged: (val) => appState.toggleTheme(),
                      title: const Text("Dark Theme Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Switch app aesthetics to dark colors"),
                      secondary: const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryTeal),
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Reset App Data"),
                            content: const Text("Are you sure you want to delete all cached settings, family members, history logs, and prescription files? This action is permanent."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await appState.resetDatabase();
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
                                child: const Text("Reset All"),
                              ),
                            ],
                          ),
                        );
                      },
                      title: const Text("Reset App Cache", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.alertRed)),
                      subtitle: const Text("Wipe all local data and restore defaults"),
                      leading: const Icon(Icons.refresh_rounded, color: AppTheme.alertRed),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyProfilesList(BuildContext context, AppStateProvider appState, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appState.familyMembers.length,
      itemBuilder: (context, index) {
        final member = appState.familyMembers[index];
        final isSelf = member.id == 'self';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                radius: 20,
                child: Icon(
                  _avatarIcons[member.avatarIndex % _avatarIcons.length],
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      member.relation,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelf)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Delete Profile"),
                        content: Text("Are you sure you want to delete ${member.name} and clear all associated schedules?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: () {
                              appState.deleteFamilyMember(member.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.alertRed, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionLocker(BuildContext context, AppStateProvider appState, bool isDark) {
    final prescriptions = appState.activePrescriptions;

    if (prescriptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
        alignment: Alignment.center,
        child: const Text("Prescription cabinet locker is empty.", style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final presc = prescriptions[index];
        final uploadDateStr = DateFormat('MMM dd, yyyy').format(presc.uploadDate);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                radius: 20,
                child: Icon(Icons.description_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      presc.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${presc.doctorName} • Scanned $uploadDateStr",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: presc.extractedMedicines.map((med) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.2), width: 0.5),
                          ),
                          child: Text(
                            med,
                            style: const TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestUtilityCard(BuildContext context, AppStateProvider appState, bool isDark) {
    final activeMeds = appState.activeMedicines;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Simulate Medication Alarm Trigger",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Quickly test the full-screen interactive reminder sheet layout by simulating an immediate alarm event.",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          if (activeMeds.isEmpty)
            const Text(
              "Add a medicine first to enable alert testing.",
              style: TextStyle(color: AppTheme.alertOrange, fontSize: 12, fontWeight: FontWeight.bold),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                final firstMed = activeMeds.first;
                final firstTime = firstMed.reminderTimes.first;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Triggering simulated medicine alarm in 1.5 seconds..."),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                Future.delayed(const Duration(milliseconds: 1500), () {
                  appState.triggerReminderMock(firstMed, firstTime);
                });
              },
              icon: const Icon(Icons.alarm_add_rounded, size: 20),
              label: const Text("Simulate Medication Alert"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
    );
  }
}
