import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class RegistrationDetailsScreen extends StatefulWidget {
  final List<String> registrationIds;

  const RegistrationDetailsScreen({super.key, required this.registrationIds});

  @override
  _RegistrationDetailsScreenState createState() => _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> {
  List registrations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRegistrationData();
  }

  Future<void> fetchRegistrationData() async {
    const url = 'https://27.123.248.68:4000/api/register/getRegistrations';

    try {
      var client = http.Client();
      // Prepare the request body
      final body = json.encode({"registrationIds": widget.registrationIds});
      
      // Fetch registration data
      http.Response response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        setState(() {
          registrations = decodedResponse['registrations'];
          isLoading = false;
        });
      } else {
        throw HttpException('Failed to load registration data, status code: ${response.statusCode}');
      }
    } on SocketException {
      _showErrorDialog('Network error. Please check your internet connection.');
    } on TimeoutException {
      _showErrorDialog('Request timed out. Please try again later.');
    } catch (e) {
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
        title: const Text('Registration Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : registrations.isEmpty
              ? const Center(child: Text('No registration data available'))
              : ListView.builder(
                  itemCount: registrations.length,
                  itemBuilder: (context, index) {
                    final registration = registrations[index];
                    final eventDetails = registration['eventDetails'] ?? {};
                    final payment = registration['payment'] ?? {};

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text('Event Name: ${eventDetails['eventName'] ?? 'N/A'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Venue: ${eventDetails['venue'] ?? 'N/A'}'),
                            Text('Amount Paid: ${payment['amount'] ?? 'N/A'}'),
                            Text('Team Name: ${registration['teamName'] ?? 'N/A'}'),
                            Text('College: ${registration['college'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text('Members:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ...List.generate(
                              registration['members']?.length ?? 0,
                              (i) => Text(
                                '${registration['members'][i]['name']} - ${registration['members'][i]['collegeId']}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
