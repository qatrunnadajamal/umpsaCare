
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/availabilityController.dart';
import '../../controllers/notificationController.dart';
import '../../model/availability.dart';

class SlotDocView extends StatefulWidget {
  const SlotDocView({super.key});

  @override
  State<SlotDocView> createState() => _SlotDocViewState();
}

class _SlotDocViewState extends State<SlotDocView> {
  final AvailabilityController _controller = AvailabilityController();
  final NotificationController _notificationController = NotificationController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late String _doctorId;
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color bgGrey = Color(0xFFF5F7FA);
  final Map<DateTime, List<Availability>> _slotsPerDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadSlots();
  }

  void _loadSlots() {
    _controller.getAvailabilities(_doctorId).listen((slots) {
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
              // Handle error 
            }
          }
        });
      }
    });
  }

  DateTime _getCleanLocalDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Color? _getDayMarkerColor(DateTime day) {
    final cleanDay = _getCleanLocalDate(day);
    if (!_slotsPerDay.containsKey(cleanDay)) return null;

    final slots = _slotsPerDay[cleanDay]!;
    if (slots.any((s) => s.avStatus == 'blocked')) return Colors.grey;
    if (slots.any((s) => s.avStatus == 'unavailable')) return Colors.redAccent;
    if (slots.any((s) => s.avStatus == 'available')) return primaryTeal;

    return null;
  }

  String _formatDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _formatTimeAMPM(String time24) {
    try {
      final parts = time24.split(':');
      final dt = DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24;
    }
  }

  void _toggleSlot(Availability slot) {
    final newStatus =
        slot.avStatus == 'available' ? 'unavailable' : 'available';
    _controller.toggleStatus(slot.availabilityId, newStatus);
  }

  Future<void> _blockDay(DateTime day) async {
    final dateStr = _formatDateKey(day);
    await _controller.blockDay(_doctorId, dateStr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Blocked $dateStr'), backgroundColor: Colors.grey),
      );
    }
  }

  // NOTI
  Future<void> _sendSlotNotification({
    required String date,
    required String time,
  }) async {
    final referenceId = '${_doctorId}_${date}_$time';

    try {
      await _notificationController.createNotification(
        userId: _doctorId,
        type: "slot_assigned",
        title: "Slot Created",
        message: "You successfully added a new slot on $date at $time.",
        referenceId: referenceId,
      );

      // SUCCESS
      if (mounted) {
        showDialog(
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
                        size: 40, color: primaryTeal),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Success!",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Slot for $date at $time has been added.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("OK",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(" Error sending notification: $e");
    }
  }

  // WIDGET 

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    String currentDateString = _selectedDay != null
        ? DateFormat('EEE, dd MMM yyyy').format(_selectedDay!)
        : "Select a Date";
    return Scaffold(
      backgroundColor: bgGrey,
      appBar: AppBar(
        title: const Text(
          'Manage Availability',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryTeal,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.block, color: Color.fromARGB(255, 255, 0, 0)),
            tooltip: 'Block selected day',
            onPressed:
                _selectedDay == null ? null : () => _blockDay(_selectedDay!),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, bottom: 10, top: 10),
            color: Colors.white,
            child: Text(
              'Selected: $currentDateString',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // CALENDAR 
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
                TableCalendar(
                  key: ValueKey(_slotsPerDay.hashCode),
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  daysOfWeekHeight: isTablet ? 44 : 32, 
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                        color: primaryTeal, fontWeight: FontWeight.bold),
                  ),
                  
                  // MARK DOT
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final color = _getDayMarkerColor(day);
                      if (color == null) return null;
                      return Positioned(
                        bottom: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                _buildLegend(),
              ],
            ),
          ),

          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDay != null
                    ? "Slots for ${DateFormat('dd MMM').format(_selectedDay!)}"
                    : "Select a date to view slots",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                    fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SLOT LIST
          Expanded(
            child: StreamBuilder<List<Availability>>(
              stream: _controller.getAvailabilities(_doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryTeal));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState("No availability set yet.");
                }

                final allSlots = snapshot.data!;
                final daySlots = _selectedDay == null
                    ? []
                    : allSlots
                        .where((slot) =>
                            slot.avDate == _formatDateKey(_selectedDay!))
                        .toList()
                      ..sort(
                          (a, b) => a.avTimestamp.compareTo(b.avTimestamp));

                if (daySlots.isEmpty) {
                  return _buildEmptyState("No slots for this date.");
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: daySlots.length,
                  itemBuilder: (context, index) {
                    final slot = daySlots[index];
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
                                : Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: isAvailable
                                ? primaryTeal
                                : Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          displayTime,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${slot.avDuration} mins • ${slot.avStatus.toUpperCase()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleSlot(slot),
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
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedDay != null) _buildAddSlotButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
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

  Widget _buildAddSlotButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (_selectedDay == null) return;

          final time = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 9, minute: 0));
          
          if (time != null) {
            final timestamp =
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
            final availabilityId =
                "${_doctorId}_${_formatDateKey(_selectedDay!)}_${timestamp.replaceAll(':', '-')}";

            final newSlot = Availability(
              availabilityId: availabilityId,
              doctorId: _doctorId,
              avDate: _formatDateKey(_selectedDay!),
              avTimestamp: timestamp,
              avDuration: 30,
              avStatus: 'available',
            );

            // SAVE
            await _controller.setAvailability(newSlot, context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: Text(
          "Add Slot for ${DateFormat('dd MMM').format(_selectedDay!)}",
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

