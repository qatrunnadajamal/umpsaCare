import 'package:flutter/material.dart';
class SuccessPopup extends StatelessWidget {
  final VoidCallback onOkPressed;
  final String title;
  final String message;

  const SuccessPopup({
    super.key,
    required this.onOkPressed,
    this.title = "Congratulations!",
    this.message = "Sign up successful!",
  });

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF4CAF50);
    const Color buttonBlue =  Color(0xFF00A0C6); 

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: successGreen.withOpacity(0.5), width: 2),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.check,
                color: successGreen,
                size: 50,
              ),
            ),
            
            const SizedBox(height: 25),

            // TITTLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 10),

            // SUB-MESSAGE
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            
            const SizedBox(height: 30),

            // OK 
            SizedBox(
              width: 150, 
              child: ElevatedButton(
                onPressed: onOkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0, 
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}