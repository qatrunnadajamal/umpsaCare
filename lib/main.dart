
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'view/login/loginPage.dart';
import 'view/manageAppointment/appointmentBookPage.dart'; 
import 'view/manageAppointment/appointmentBookPageD.dart'; 
import 'view/manageAppointment/appointmentBookPageS.dart'; 
import 'services/notification_service.dart';
import 'services/onesignal_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT FIRE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tz.initializeTimeZones();

  // INIT NOTI SERVICES
  await NotificationService.init();

  // IINIT ONE SIGNAL
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("14f4cb65-a8dd-465c-bace-2f65fda611f3");
  OneSignal.Notifications.requestPermission(true);
  setupOneSignalUserBinding();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const RootPage(),
    );
  }
}

/// ROOTPAGE
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<Widget> _getHomePage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // NOT LOG IN
      return const LoginPage();
    }

    //FECTH USER TYPE
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userType = doc.data()?['user_type'] ?? '';

      if (userType == 'Student') return const AppointmentBookPage();
      if (userType == 'Doctor') return const AppointmentBookPageD();
      if (userType == 'PKU Staff') return const AppointmentBookPageS();

      // fallback
      return const LoginPage();
    } catch (e) {
      print("Error fetching user_type: $e");
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getHomePage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data!;
      },
    );
  }
}


// ignore_for_file: unused_local_variable