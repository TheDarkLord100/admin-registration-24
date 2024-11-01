import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:youthopia_admin_app/event_detail.dart';


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
                                  EventDetailScreen(eventId: event['event_id'], eventName: event['event_name'],),
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
