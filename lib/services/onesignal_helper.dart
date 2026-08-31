import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void setupOneSignalUserBinding() {
  // Observe push subscription state changes
  OneSignal.User.pushSubscription.addObserver((state) async {
    final playerId = state.current.id;
    final user = FirebaseAuth.instance.currentUser;

    if (playerId != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'onesignal_id': playerId,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('OneSignal ID saved: $playerId');
    }
  });
}

/// SAVE ONE SIGNAL
Future<void> forceSaveOneSignalIdAfterLogin({int retries = 4}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print("No logged-in user yet");
    return;
  }

  int attempt = 0;
  String? playerId;

  while (attempt < retries) {
    playerId = OneSignal.User.pushSubscription.id;

    if (playerId != null && playerId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'onesignal_id': playerId,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("OneSignal ID saved after login: $playerId");
      return;
    }

    // Wait 1 second before retrying
    await Future.delayed(const Duration(seconds: 1));
    attempt++;
    print("Retrying OneSignal ID... attempt $attempt");
  }

  print("Failed to get OneSignal ID after $retries attempts.");
}
