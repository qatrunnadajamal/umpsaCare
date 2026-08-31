
import 'package:flutter/material.dart';
import '../../controllers/appointmentController.dart';
import 'appointmentBookPage.dart'; // 

const Color primaryCyan = Color(0xFF00A0C6);
const Color darkBlue = Color(0xFF003B46);
const Color bgCoolGrey = Color(0xFFF4F6F8);

class CancelForm extends StatefulWidget {
  final String appointmentId;
  final String studentId;

  const CancelForm({
    Key? key,
    required this.appointmentId,
    required this.studentId,
  }) : super(key: key);

  @override
  State<CancelForm> createState() => _CancelFormState();
}

class _CancelFormState extends State<CancelForm> {
  final List<String> _options = [
    'I would like to change to another doctor',
    'I would like to change the selected service',
    'I no longer require a consultation',
    'My condition has improved',
    'I have obtained appropriate medication',
    'I need to cancel the appointment',
    'I prefer not to disclose the reason',
    'Other reasons',
  ];

  String? _selectedOption;
  final AppointmentController _controller = AppointmentController();

  //CONFRIMATION 
  Future<void> _showCancellationPopup({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required Color buttonColor,
    bool closeBoth = false,
    bool navigateHome = false, 
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (navigateHome) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const AppointmentBookPage()),
                          (route) => false,
                        );
                      } else {
                        // Close Dialog
                        Navigator.of(context).pop();
                        // Optional: Close Form Page
                        if (closeBoth) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCoolGrey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF00A2A5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cancel Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Cancellation',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final isSelected = _selectedOption == option;
                  return InkWell(
                    onTap: () => setState(() => _selectedOption = option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? primaryCyan : Colors.grey[300]!,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: primaryCyan.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? primaryCyan : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? darkBlue : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedOption == null) {
                    await _showCancellationPopup(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.orange,
                      title: 'No Reason Selected',
                      message: 'Please select a reason to cancel your appointment.',
                      buttonColor: Colors.orange,
                    );
                    return;
                  }

                  try {
                    await _controller.cancelAppointment(
                      widget.appointmentId,
                      _selectedOption!,
                      widget.studentId,
                    );

                    if (!mounted) return;
                    
                    await _showCancellationPopup(
                      icon: Icons.cancel_presentation_rounded,
                      iconColor: Colors.red,
                      title: 'Appointment Cancelled',
                      message: 'Appointment successfully cancelled.',
                      buttonColor:Color(0xFF00A2A5),
                      navigateHome: true, 
                    );
                  } catch (e) {
                    if (!mounted) return;
                    await _showCancellationPopup(
                      icon: Icons.error_outline,
                      iconColor: Colors.red,
                      title: 'Failed',
                      message: 'Failed to cancel. Please try again.',
                      buttonColor: Colors.red,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A2A5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}