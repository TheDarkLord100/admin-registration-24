import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_settings/app_settings.dart';
import 'RegistrationModel.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventDetailScreen(
      {super.key, required this.eventId, required this.eventName});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<RegistrationModel> eventRegistrations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    final url =
        'https://27.123.248.68:4000/api/register/getRegistrations/${widget.eventId}';

    try {
      var client = http.Client();
      http.Response response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body) as List;
        setState(() {
          eventRegistrations = decodedResponse
              .map((json) => RegistrationModel.fromJson(json))
              .toList();
        });
      } else if (response.statusCode == 404) {
        _showErrorDialog('No registrations found for this event.');
      } else {
        throw HttpException(
            'Failed to load event details, status code: ${response.statusCode}');
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

  Future<bool> _checkPermissions() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }
    status = await Permission.storage.request();
    print(status);
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showErrorDialog(
        'Storage permission is permanently denied. Please enable it in settings.',
      );
      AppSettings.openAppSettings();
    } else {
      _showErrorDialog(
        'Storage permission is required to generate the CSV file.',
      );
      AppSettings.openAppSettings();
    }
    return false;
  }

  Future<void> _generateCSV() async {
    // Check for permissions before proceeding
    if (await _checkPermissions()) {
      List<List<dynamic>> rows = [];

      // Initial headers for static fields
      List<String> headers = [
        'Team Name',
        'Email',
        'College',
        'Payment Status',
        'Amount'
      ];

      // Determine max member count across all registrations
      int maxMembers = eventRegistrations
          .map((json) => json.members.length)
          .fold(0, (prev, curr) => curr > prev ? curr : prev);

      // Add dynamic headers for each member based on maxMembers
      for (int i = 1; i <= maxMembers; i++) {
        headers.addAll([
          'Member $i Name',
          'Member $i College ID',
          'Member $i Personal ID',
        ]);
      }

      // Add headers to rows
      rows.add(headers);

      // Populate rows with registration data
      for (var regModel in eventRegistrations) {

        // Add base registration details
        List<dynamic> row = [
          regModel.teamName,
          regModel.email,
          regModel.college,
          regModel.payment.paid ? 'Paid' : 'Not Paid',
          regModel.payment.amount,
        ];

        // Add each member's details to the row
        for (int i = 0; i < maxMembers; i++) {
          if (i < regModel.members.length) {
            Member member = regModel.members[i];
            row.addAll([
              member.name,
              member.collegeId,
              member.personalId,
            ]);
          } else {
            // Fill in empty values for missing members
            row.addAll(['', '', '']);
          }
        }

        // Add the populated row to rows list
        rows.add(row);
      }

      // Convert rows to CSV format
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/event_registrations.csv';
      final File file = File(path);

      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file generated successfully at: $path')),
      );
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
        title: Text(widget.eventName),
        actions: [
          isLoading
              ? const Text('0')
              : Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    eventRegistrations.length.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventRegistrations.isEmpty
              ? const Center(
                  child: Text('No registrations found for this event.'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _generateCSV, //_generateCSV,
                          child: const Text('Print Candidates'),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: eventRegistrations.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 16),
                              child: DetailsCard(
                                  details: eventRegistrations[index]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class DetailsCard extends StatelessWidget {
  final RegistrationModel details;
  const DetailsCard({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registration ID: ${details.regID}'),
        Text('Team Name: ${details.teamName}'),
        Text('College: ${details.college}'),
        Text('Member Count: ${details.members.length}'),
        MemberList(members: details.members),
        Text('Payment Status: ${details.payment.paid ? 'Paid' : 'Not Paid'}'),
        Text('Amount: ${details.payment.amount}')
      ],
    );
  }
}

class MemberList extends StatelessWidget {
  final List<Member> members;
  const MemberList({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: members
          .map((member) => Text(
              'Member Name: ${member.name} - College ID: ${member.collegeId}'))
          .toList(),
    );
  }
}
