import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_settings/app_settings.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
  const url = 'https://27.123.248.68:4000/api/events';

  try {
    var client = http.Client();
    http.Response response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body) as Map<String, dynamic>;
      if (decodedResponse.containsKey('events')) {
        final List fetchedEvents = decodedResponse["events"];
        setState(() {
          events = fetchedEvents;
          isLoading = false;
        });
      } else {
        throw Exception('Unexpected response format.');
      }
    } else {
      throw HttpException('Failed to load events, status code: ${response.statusCode}');
    }
  } on SocketException {
    _showErrorDialog('Network error. Please check your internet connection.');
  } on TimeoutException {
    _showErrorDialog('Request timed out. Please try again later.');
  } catch (e) {
    print("Error fetching events: $e");
    _showErrorDialog('An unexpected error occurred. Please try again.');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events List'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? const Center(child: Text('No events available'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      child: ListTile(
                        title: Text(event['event_name'] ?? 'No name'),
                        subtitle: Text(event['event_id'] ?? 'No ID'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailScreen(eventId: event['event_id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic> eventDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
  final url = 'https://27.123.248.68:4000/api/register/getRegistrations/${widget.eventId}';

  try {
    var client = http.Client();
    http.Response response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body) as Map<String, dynamic>;
      if (decodedResponse.containsKey('registrations')) {
        setState(() {
          eventDetails = decodedResponse;
          isLoading = false;
        });
      } else {
        throw Exception('Unexpected JSON format.');
      }
    } else {
      throw HttpException('Failed to load event details, status code: ${response.statusCode}');
    }
  } on SocketException {
    _showErrorDialog('Network error. Please check your internet connection.');
  } on TimeoutException {
    _showErrorDialog('Request timed out. Please try again later.');
  } catch (e) {
    print("Error fetching event details: $e");
    _showErrorDialog('An unexpected error occurred. Please try again.');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  Future<void> _generateCSV() async {
    if (await _checkPermissions()) {
      List<List<dynamic>> rows = [];
      rows.add(['Team Name', 'Payment Status', 'Member Name']);

      final registrations = eventDetails['registrations'] as List;
      for (var registration in registrations) {
        String teamName = registration['teamName'] ?? 'N/A';
        String paymentStatus = registration['payment']['paid'] ? 'Paid' : 'Not Paid';
        List<dynamic> memberNames = registration['members'].map((member) => member['name']).toList();

        for (var name in memberNames) {
          rows.add([teamName, paymentStatus, name]);
        }
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/event_registrations.csv';
      final File file = File(path);

      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file generated successfully: $path')),
      );
    }
  }

  Future<bool> _checkPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (status.isDenied) {
        _showErrorDialog('Storage permission is denied. Please enable it in settings.');
        AppSettings.openAppSettings(); // Open app settings if denied
        return false;
      }
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(eventDetails['event_name'] ?? 'Event Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event ID: ${eventDetails['event_id'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Event Name: ${eventDetails['event_name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _generateCSV,
                    child: const Text('Print Candidates'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registration Details: ${eventDetails['registrations'] ?? 'No registrations available'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
