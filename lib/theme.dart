import 'package:flutter/material.dart';

// COLOUR
class AppColors {
  static const Color primaryTeal = Color(0xFF00A2A5);
  static const Color background = Colors.white;
  static const Color unselectedIcon = Colors.black;
  static const Color shadow = Colors.grey;
}

// TEXT
class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
}

//APP BAR
AppBar buildAppBar(String title, {bool centerTitle = true}) {
  return AppBar(
    title: Text(title, style: AppTextStyles.appBarTitle),
    centerTitle: centerTitle,
    backgroundColor: AppColors.background,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
  );
}
