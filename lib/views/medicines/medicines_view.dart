import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/models/medicine.dart';
import 'package:orma_dose/views/medicines/add_medicine_view.dart';

class MedicinesView extends StatefulWidget {
  const MedicinesView({super.key});

  @override
  State<MedicinesView> createState() => _MedicinesViewState();
}

class _MedicinesViewState extends State<MedicinesView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final medicines = appState.activeMedicines;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter by search
    final filtered = medicines.where((med) {
      return med.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Medicines",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddMedicineView(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
                      tooltip: 'Add new medicine',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? AppTheme.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryTeal,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Inventory List
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final med = filtered[index];
                          return _buildMedicineInventoryCard(context, appState, med, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineInventoryCard(
    BuildContext context, 
    AppStateProvider appState, 
    Medicine med, 
    bool isDark,
  ) {
    // Stock ratio
    final double stockRatio = med.initialStock == 0 ? 0.0 : (med.remainingStock / med.initialStock);
    final isLowStock = med.remainingStock <= med.refillThreshold;
    final isSyrup = med.type == 'syrup';
    final unit = isSyrup ? 'ml' : 'pcs';

    // Stock color mapping
    Color stockColor;
    if (isLowStock) {
      stockColor = AppTheme.alertRed;
    } else if (stockRatio < 0.4) {
      stockColor = AppTheme.alertOrange;
    } else {
      stockColor = AppTheme.accentGreen;
    }

    // Medicine Icon mapping
    IconData medIcon = Icons.circle;
    switch (med.type) {
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLowStock 
              ? AppTheme.alertRed.withOpacity(0.3) 
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Icon, Type, Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                radius: 22,
                child: Icon(medIcon, color: AppTheme.primaryTeal, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${med.dosage} • ${med.type.toUpperCase()}",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showDeleteConfirmDialog(context, appState, med);
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.alertRed.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          // Row 2: Timings & Frequencies info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Schedule Freq",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    med.frequencyType == 'daily' 
                        ? 'Everyday' 
                        : 'Weekly (${med.selectedDays.length} days)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Reminder Times",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    med.reminderTimes.join(', '),
                    style: const TextStyle(
                      fontSize: 13, 
                      fontWeight: FontWeight.bold, 
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Stock bar and Refill Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Stock: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      Text(
                        "${med.remainingStock} / ${med.initialStock} $unit",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ],
                  ),
                  if (isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.alertRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "LOW STOCK",
                        style: TextStyle(
                          color: AppTheme.alertRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Stock bar indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: stockRatio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                ),
              ),
              const SizedBox(height: 12),
              // Refill Increment Toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Quick Buy:",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRefillButton(appState, med.id, isSyrup ? 100 : 10, isDark),
                  const SizedBox(width: 6),
                  _buildRefillButton(appState, med.id, isSyrup ? 250 : 30, isDark),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefillButton(AppStateProvider appState, String medId, int qty, bool isDark) {
    return ElevatedButton(
      onPressed: () {
        appState.refillMedicine(medId, qty);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Stock refilled successfully! +$qty added."),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        minimumSize: const Size(60, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        "+$qty",
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AppStateProvider appState, Medicine med) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Medicine"),
          content: Text("Are you sure you want to delete ${med.name}? All history logs for this medicine will be permanently cleared."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                appState.deleteMedicine(med.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Deleted ${med.name}."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.alertRed,
                minimumSize: const Size(80, 40),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            child: Icon(Icons.medical_services_rounded, size: 40, color: AppTheme.primaryTeal),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Medicines Logged",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add medications using the '+' button at the top right to start tracking.",
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
