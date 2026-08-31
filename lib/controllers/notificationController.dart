
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'notifications';

  //  CREATE
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    required String referenceId,
    BuildContext? context,
    bool showPopup = false,
  }) async {
    try {
      final docRef = _firestore.collection(collectionName).doc();
      await docRef.set({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'reference_id': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      await NotificationService.showNotification(title, message);

      if (showPopup && context != null && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 60, color: Colors.green),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('OK'),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print(" Error creating notification: $e");
    }
  }

  //SEND
  Future<void> sendPushToStudent({
    required String studentId,
    required String type,
    required String title,
    required String message,
    required String referenceId,
  }) async {
    try {
      // ID
      DocumentSnapshot snap =
          await _firestore.collection("users").doc(studentId).get();

      if (!snap.exists || snap['onesignal_id'] == null) {
        print(" Student has no OneSignal ID saved");
        return;
      }

      final playerId = snap['onesignal_id'];

      // OneSignal REST API endpoint
      const String url = "https://api.onesignal.com/notifications";

      // Your OneSignal App ID + REST API Key
      const String appId = "14f4cb65-a8dd-465c-bace-2f65fda611f3";
      const String apiKey = "os_v2_app_ct2mwzni3vdfzowof5s73jqr6oljkbpbuolekavsiqhoogbrnoaw74mrzhgatbhp33gmiinzin3gbwmgkyp3iqg6wgzia3wxs6ybrki"; 

      //Build JSON payload
      final body = {
        "app_id": appId,
        "include_player_ids": [playerId],
        "headings": {"en": title},
        "contents": {"en": message},
        "data": {
          "type": type,
          "reference_id": referenceId,
        }
      };

      // Send HTTP POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Basic $apiKey",
        },
        body: jsonEncode(body),
      );

      print("OneSignal Response: ${response.body}");

    } catch (e) {
      print("Error sending OneSignal push: $e");
    }
  }
}
