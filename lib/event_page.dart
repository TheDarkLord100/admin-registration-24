import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For decoding JSON
import 'dart:io'; // For handling socket exceptions
import 'dart:async'; // For handling timeouts

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
    fetchEvents(); // Fetch events when the page is initialized
  }

  // Function to fetch data from API
  Future<void> fetchEvents() async {
    const url = 'https://27.123.248.68:4000/api/events';

    try {
      // Send GET request with a timeout to avoid infinite loading
      var client = http.Client();
      http.Response response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Check if the response body can be decoded as JSON
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map && decodedResponse.containsKey('events')) {
          final List fetchedEvents = decodedResponse["events"];
          setState(() {
            events = fetchedEvents;
            isLoading = false;
          });
        } else {
          throw Exception('Malformed response data');
        }
      } else {
        // If response status is not OK, throw an error with the status code
        throw HttpException('Failed to load events, status code: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // Handle network error (specific case)
      setState(() {
        isLoading = false;
      });
      print('Network error: $e');
      _showErrorDialog('Network error. Please check your internet connection.');
    } on TimeoutException catch (e) {
      // Handle timeout error (specific case)
      setState(() {
        isLoading = false;
      });
      print('Timeout error: $e');
      _showErrorDialog('Request timed out. Please try again later.');
    } catch (e) {
      // Handle general errors
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  // Function to show error dialog
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
                              builder: (context) => EventDetailScreen(event: event),
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

class EventDetailScreen extends StatelessWidget {
  final dynamic event; 

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['event_name'] ?? 'Event Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event ID: ${event['event_id'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Event Name: ${event['event_name'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
           
          ],
        ),
      ),
    );
  }
}
