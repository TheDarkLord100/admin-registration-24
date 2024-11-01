import 'package:flutter/material.dart';
import 'dart:io'; // For SSL certificate overrides
import 'event_page.dart'; // Import your EventPage here

// Override to bypass SSL certificate validation (For testing purposes only)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // Apply the SSL override globally
  // HttpOverrides.global = MyHttpOverrides();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // To hide the debug banner
      title: 'Flutter API Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const EventPage(), // Set EventPage as the home page
    );
  }
}
