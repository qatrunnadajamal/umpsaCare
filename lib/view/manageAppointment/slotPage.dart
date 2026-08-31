import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../../controllers/availabilityController.dart';
import '../../../model/availability.dart';

class SlotPage extends StatefulWidget {
  final String doctorId;
  const SlotPage({super.key, required this.doctorId});

  @override
  State<SlotPage> createState() => _SlotPageState();
}

class _SlotPageState extends State<SlotPage> {
  final AvailabilityController _controller = AvailabilityController();
  final Uuid _uuid = const Uuid();

  bool? isStaff;
  bool _isLoadingRole = true;
  String _doctorName = "Loading...";

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedSingleDay = DateTime.now();
  final Set<DateTime> _selectedDays = {};
  final Map<DateTime, List<Availability>> _slotsPerDay = {};

  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _selectedSingleDay = _focusedDay;
    _initializePageData();

    // Listen to stream to update the calendar dots/colors
    _controller.getAvailabilities(widget.doctorId).listen((slots) {
      if (mounted) {
        setState(() {
          _slotsPerDay.clear();
          for (var slot in slots) {
            try {
              final date = _getCleanLocalDate(
                  DateFormat('yyyy-MM-dd').parse(slot.avDate));
              final list = _slotsPerDay.putIfAbsent(date, () => []);
              if (!list.any((s) =>
                  s.avTimestamp == slot.avTimestamp &&
                  s.availabilityId == slot.availabilityId)) {
                list.add(slot);
              }
            } catch (e) {
              print("Error parsing date for slot: $e");
            }
          }
        });
      }
    });
  }

  Future<void> _initializePageData() async {
    await Future.wait([
      _fetchDoctorName(),
      _fetchUserRole(),
    ]);
    if (mounted) {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  Future<void> _fetchDoctorName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _doctorName = doc.data()?['full_name'] ?? 'Unknown Doctor';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _doctorName = "Doctor");
    }
  }

  Future<void> _fetchUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists) {
          final String rawType =
              doc.data()?['user_type']?.toString().toLowerCase() ?? '';
          if (mounted) {
            setState(() {
              isStaff = rawType.contains('staff') ||
                  rawType.contains('doctor') ||
                  rawType.contains('admin');
            });
          }
        } else {
          if (mounted) setState(() => isStaff = false);
        }
      } catch (e) {
        if (mounted) setState(() => isStaff = false);
      }
    } else {
      if (mounted) setState(() => isStaff = false);
    }
  }

  DateTime _getCleanLocalDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Color? _getDayColor(DateTime day) {
    final cleanDay = _getCleanLocalDate(day);
    if (!_slotsPerDay.containsKey(cleanDay)) return null;
    final slots = _slotsPerDay[cleanDay]!;
    if (slots.any((s) => s.avStatus == 'blocked')) return Colors.grey;
    if (slots.any((s) => s.avStatus == 'unavailable')) return Colors.redAccent;
    if (slots.any((s) => s.avStatus == 'available')) return primaryTeal;
    return null;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final cleanSelected = _getCleanLocalDate(selectedDay);
    setState(() {
      _focusedDay = focusedDay;
      _selectedSingleDay = cleanSelected;
      if (_selectedDays.contains(cleanSelected)) {
        _selectedDays.remove(cleanSelected);
      } else {
        _selectedDays.add(cleanSelected);
      }
    });
  }

  String _formatTimeAMPM(String time24) {
    try {
      final parts = time24.split(':');
      final dt =
          DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24;
    }
  }

  void _showBulkTimePicker(BuildContext context) {
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Set Bulk Availability',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('For ${_selectedDays.length} selected day(s)',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    ListTile(
                      title: const Text("Start Time"),
                      trailing: Text(startTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryTeal)),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: startTime);
                        if (t != null) setDialogState(() => startTime = t);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text("End Time"),
                      trailing: Text(endTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryTeal)),
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context, initialTime: endTime);
                        if (t != null) setDialogState(() => endTime = t);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _processBulkCreation(startTime, endTime);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Generate Slots'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // BULK PROCESS
  Future<void> _processBulkCreation(TimeOfDay start, TimeOfDay end) async {
    if (isStaff != true) {
      String msg = isStaff == null
          ? 'Loading user permissions...'
          : 'Unauthorized: Only staff can manage slots.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    List<TimeOfDay> generatedTimes = [];
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    while (startMinutes < endMinutes) {
      final hour = startMinutes ~/ 60;
      final minute = startMinutes % 60;
      generatedTimes.add(TimeOfDay(hour: hour, minute: minute));
      startMinutes += 30;
    }

    if (generatedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invalid time range. End time must be at least 30 mins after start time.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: primaryTeal)),
    );

    try {
      await _controller.setBulkAvailability(
        doctorId: widget.doctorId,
        dates: _selectedDays,
        times: generatedTimes,
        duration: 30,
        context: null,
        isStaff: isStaff!,
      );

      if (mounted) {
        Navigator.pop(context);

        // CONFIRMATION DIALOG
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text('Success',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(
                    'Successfully added ${generatedTimes.length} slots per day for ${_selectedDays.length} day(s).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        setState(() => _selectedDays.clear());
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating slots: $e')),
        );
      }
    }
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
        backgroundColor: bgGrey,
        body: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    final selectedDateString =
        DateFormat('yyyy-MM-dd').format(_selectedSingleDay);

    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Manage Schedule',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 14),
            ),
            Text(
              _doctorName.contains('Dr.') ? _doctorName : 'Dr. $_doctorName',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, bottom: 10, top: 10),
            color: Colors.white,
            child: Text(
              'Today: ${DateFormat('EEE, dd MMM yyyy').format(_selectedSingleDay)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ),
        ),
      ),
    
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildCalendar(), // Uses updated builder logic below
                  const Divider(height: 1),
                  _buildLegend(),
                  if (_selectedDays.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildAvailabilityToggle(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedDays.isEmpty
                      ? 'Select multiple dates to set bulk availability.'
                      : 'Selected ${_selectedDays.length} date(s).',
                  style: TextStyle(
                      color: _selectedDays.isEmpty
                          ? const Color.fromARGB(255, 0, 0, 0)
                          : primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),

         
            StreamBuilder<List<Availability>>(
              stream: _controller.getAvailabilities(widget.doctorId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                        child: CircularProgressIndicator(color: primaryTeal)),
                  );
                }

                final slots = snapshot.data!
                    .where((s) => s.avDate == selectedDateString)
                    .toList()
                  ..sort((a, b) => a.avTimestamp.compareTo(b.avTimestamp));

                if (slots.isEmpty) {
                  return SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "No slots for ${DateFormat('dd MMM').format(_selectedSingleDay)}",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isAvailable = slot.avStatus == 'available';
                    final displayTime = _formatTimeAMPM(slot.avTimestamp);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? primaryTeal.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            color: isAvailable ? primaryTeal : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          displayTime,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                            "${slot.avDuration} mins • ${slot.avStatus.toUpperCase()}",
                            style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                final newStatus = slot.avStatus == 'available'
                                    ? 'unavailable'
                                    : 'available';
                                _controller.toggleStatus(
                                    slot.availabilityId, newStatus);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAvailable
                                    ? primaryTeal
                                    : Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                  isAvailable ? 'Active' : 'Inactive',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () async {
                                await _controller
                                    .deleteAvailability(slot.availabilityId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Slot deleted')));
                                }
                              },
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.grey),
                              tooltip: 'Delete Slot',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            _buildAddSlotButton(selectedDateString),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _selectedDays.isEmpty
                ? null
                : () => _showBulkTimePicker(context),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: const Text('Set Bulk Availability'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _selectedDays.isEmpty ? Colors.grey : primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: _selectedDays.isEmpty
              ? null
              : () => setState(() => _selectedDays.clear()),
          child: const Text('Clear Selection',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _LegendItem(color: Colors.grey, label: 'Blocked'),
          SizedBox(width: 16),
          _LegendItem(color: Colors.redAccent, label: 'Unavailable'),
          SizedBox(width: 16),
          _LegendItem(color: primaryTeal, label: 'Available'),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final rowHeight = isTablet ? 70.0 : 50.0;
    final daysOfWeekHeight = isTablet ? 40.0 : 30.0;

    return TableCalendar(
      key: ValueKey(_slotsPerDay.hashCode),
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      rowHeight: rowHeight,
      daysOfWeekHeight: daysOfWeekHeight,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: primaryTeal.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
            color: primaryTeal, fontWeight: FontWeight.bold),
        selectedDecoration: const BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      selectedDayPredicate: (day) =>
          _selectedDays.contains(_getCleanLocalDate(day)),
      onDaySelected: _onDaySelected,
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildCustomDay(day, isSelected: false);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildCustomDay(day,
              isSelected: _selectedDays.contains(_getCleanLocalDate(day)));
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildCustomDay(day, isSelected: true);
        },
      ),
    );
  }

  // color
  Widget? _buildCustomDay(DateTime day, {required bool isSelected}) {
    final bgColor = _getDayColor(day);
    if (bgColor == null) return null; 
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.black54, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAddSlotButton(String selectedDateString) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (isStaff == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('User role loading, please wait...')),
            );
            return;
          }
          if (isStaff != true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unauthorized: Only staff can manage slots.')),
            );
            return;
          }

          final time = await showTimePicker(
              context: context, initialTime: TimeOfDay.now());
          if (time != null) {
            final timestamp =
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
            final availabilityId =
                "${widget.doctorId}_${selectedDateString}_${timestamp.replaceAll(':', '-')}";

            final newSlot = Availability(
              availabilityId: availabilityId,
              doctorId: widget.doctorId,
              avDate: selectedDateString,
              avTimestamp: timestamp,
              avDuration: 30,
              avStatus: 'available',
            );

            await _controller.setAvailability(newSlot, context, isStaff!);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          "Add Slot for ${DateFormat('dd MMM').format(_selectedSingleDay)}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
