import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/models/medicine.dart';

class AddMedicineView extends StatefulWidget {
  const AddMedicineView({super.key});

  @override
  State<AddMedicineView> createState() => _AddMedicineViewState();
}

class _AddMedicineViewState extends State<AddMedicineView> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  
  String _selectedType = 'tablet'; // tablet, capsule, syrup, injection, drops
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String _frequencyType = 'daily'; // daily, weekly
  List<int> _selectedDays = []; // 1 = Mon, 7 = Sun
  List<String> _reminderTimes = ['08:00'];
  
  final _initialStockController = TextEditingController(text: '30');
  final _refillThresholdController = TextEditingController(text: '5');
  bool _isRefillAlertEnabled = true;

  // Scanner Simulator States
  bool _showScanner = false;
  bool _isScanning = false;
  double _laserPosition = 0.0;
  List<String> _scannerLogs = [];
  Timer? _laserTimer;
  Timer? _logTimer;

  final List<Map<String, dynamic>> _medTypes = [
    {'id': 'tablet', 'label': 'Tablet', 'icon': Icons.adjust_rounded},
    {'id': 'capsule', 'label': 'Capsule', 'icon': Icons.egg_alt_rounded},
    {'id': 'syrup', 'label': 'Syrup', 'icon': Icons.vaccines_rounded},
    {'id': 'injection', 'label': 'Injection', 'icon': Icons.colorize_rounded},
    {'id': 'drops', 'label': 'Drops', 'icon': Icons.water_drop_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _initialStockController.dispose();
    _refillThresholdController.dispose();
    _laserTimer?.cancel();
    _logTimer?.cancel();
    super.dispose();
  }

  void _addReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final min = picked.minute.toString().padLeft(2, '0');
      final newTime = "$hour:$min";
      if (!_reminderTimes.contains(newTime)) {
        setState(() {
          _reminderTimes.add(newTime);
          _reminderTimes.sort();
        });
      }
    }
  }

  void _removeReminderTime(String time) {
    if (_reminderTimes.length > 1) {
      setState(() {
        _reminderTimes.remove(time);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("At least one reminder time is required."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleDaySelection(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  // Simulator prescription scan sequence
  void _startPrescriptionScan() {
    setState(() {
      _showScanner = true;
      _isScanning = true;
      _laserPosition = 0.0;
      _scannerLogs = ["Connecting to camera engine...", "Focusing prescription document..."];
    });

    // Animate scanning laser bar
    int step = 0;
    _laserTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _laserPosition += 0.02;
        if (_laserPosition >= 1.0) {
          _laserPosition = 0.0;
        }
      });
    });

    final logs = [
      "Image acquired. Binarizing pixel array...",
      "Detecting layout blocks...",
      "OCR Match: 'Dr. Robert Chen, Cardiologist'",
      "Rx Prescribed: Metformin 500mg",
      "Sig: Take 1 Tablet twice daily (08:00, 20:00)",
      "Qty: 60 Tablets",
      "Comparing with drug master catalog...",
      "Parsed successfully! Entity validated.",
    ];

    _logTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (step < logs.length) {
        setState(() {
          _scannerLogs.add(logs[step]);
        });
        step++;
      } else {
        _laserTimer?.cancel();
        _logTimer?.cancel();
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _applyScannedDetails() {
    setState(() {
      _nameController.text = "Metformin";
      _dosageController.text = "500mg (1 Tablet)";
      _selectedType = "tablet";
      _frequencyType = "daily";
      _reminderTimes = ["08:00", "20:00"];
      _initialStockController.text = "60";
      _refillThresholdController.text = "10";
      _showScanner = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Auto-filled from doctor prescription!"),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveForm(AppStateProvider appState) {
    if (!_formKey.currentState!.validate()) return;
    if (_frequencyType == 'weekly' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one weekday for weekly frequency."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newMed = Medicine(
      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      type: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      frequencyType: _frequencyType,
      selectedDays: _selectedDays,
      reminderTimes: _reminderTimes,
      initialStock: int.tryParse(_initialStockController.text) ?? 30,
      remainingStock: int.tryParse(_initialStockController.text) ?? 30,
      isRefillAlertEnabled: _isRefillAlertEnabled,
      refillThreshold: int.tryParse(_refillThresholdController.text) ?? 5,
      familyMemberId: appState.activeProfileId,
    );

    appState.addMedicine(newMed);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${newMed.name} added successfully!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Medicine"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // OCR Upload banner
                  _buildOCRScanBanner(context, isDark),
                  const SizedBox(height: 24),

                  // Medicine Name & Dosage
                  Text("Medicine Name", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. Paracetamol',
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text("Dosage & Strength", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dosageController,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter dosage description' : null,
                    decoration: InputDecoration(
                      hintText: 'e.g. 500mg (1 Tablet)',
                      filled: true,
                      fillColor: isDark ? AppTheme.cardDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Medicine Type Selectors
                  Text("Medicine Type", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _medTypes.length,
                      itemBuilder: (context, index) {
                        final type = _medTypes[index];
                        final isSel = _selectedType == type['id'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedType = type['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            width: 80,
                            decoration: BoxDecoration(
                              color: isSel 
                                  ? AppTheme.primaryTeal.withOpacity(0.12) 
                                  : (isDark ? AppTheme.cardDark : Colors.white),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel ? AppTheme.primaryTeal : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  type['icon'],
                                  color: isSel ? AppTheme.primaryTeal : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? AppTheme.primaryTeal : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Start Date", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) setState(() => _startDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryTeal),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("End Date", style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) setState(() => _endDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.cardDark : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryTeal),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Frequency Selection
                  Text("Reminder Frequency", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFreqButton('daily', 'Everyday'),
                      const SizedBox(width: 12),
                      _buildFreqButton('weekly', 'Specific Days'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_frequencyType == 'weekly') ...[
                    Text("Select Days", style: TextStyle(fontSize: 12, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (idx) {
                        final dayVal = idx + 1;
                        final isSel = _selectedDays.contains(dayVal);
                        final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][idx];
                        
                        return GestureDetector(
                          onTap: () => _toggleDaySelection(dayVal),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isSel 
                                ? AppTheme.primaryTeal 
                                : (isDark ? Colors.white10 : Colors.grey[200]),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Timings Custom Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Reminder Timings", style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        onPressed: _addReminderTime,
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reminderTimes.map((time) {
                      return Chip(
                        label: Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                        deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
                        onDeleted: () => _removeReminderTime(time),
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.08),
                        side: const BorderSide(color: AppTheme.primaryTeal, width: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Stock & Refill Threshold Settings
                  Text("Stock Refill Settings", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _initialStockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Starting Pills Stock',
                                  hintText: 'e.g. 30',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _refillThresholdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Low Threshold Alert',
                                  hintText: 'e.g. 5',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _isRefillAlertEnabled,
                          onChanged: (val) => setState(() => _isRefillAlertEnabled = val),
                          title: const Text("Notify me when stock runs low", style: TextStyle(fontSize: 13)),
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryTeal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Add button
                  ElevatedButton(
                    onPressed: () => _saveForm(appState),
                    child: const Text("Add Medication Schedule"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // OCR Scanner Simulation overlay
          if (_showScanner) _buildOCRScannerOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildFreqButton(String val, String text) {
    final isSel = _frequencyType == val;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequencyType = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSel 
                ? AppTheme.primaryTeal.withOpacity(0.12) 
                : (isDark ? AppTheme.cardDark : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSel ? AppTheme.primaryTeal : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              width: isSel ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? AppTheme.primaryTeal : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOCRScanBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
            child: const Icon(Icons.document_scanner_rounded, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Have a prescription slip?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  "Scan prescription to extract details instantly.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _startPrescriptionScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              minimumSize: const Size(60, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Scan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildOCRScannerOverlay(bool isDark) {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "Digital Prescription Scanner",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              
              // Prescription image box with mock lines
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Stack(
                    children: [
                      // Paper simulation lines
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 12, width: 150, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 8),
                              Container(height: 12, width: 220, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Container(height: 18, width: 120, color: AppTheme.primaryTeal.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Container(height: 10, width: 180, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 8),
                              Container(height: 10, width: 200, color: Colors.grey.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),
                      // Glowing laser scanning line animation
                      if (_isScanning)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 30),
                          top: _laserPosition * 260, // approximate height
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Diagnostics parsing console
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    itemCount: _scannerLogs.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "> ${_scannerLogs[idx]}",
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.green,
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _laserTimer?.cancel();
                      _logTimer?.cancel();
                      setState(() {
                        _showScanner = false;
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: _isScanning ? null : _applyScannedDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      minimumSize: const Size(140, 48),
                    ),
                    child: _isScanning 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Confirm & Fill"),
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
