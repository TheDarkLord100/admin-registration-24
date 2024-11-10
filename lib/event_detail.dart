import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:app_settings/app_settings.dart';
import 'package:path/path.dart' as path;
import 'RegistrationModel.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventDetailScreen({
    Key? key,
    required this.eventId,
    required this.eventName,
  }) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<RegistrationModel> eventRegistrations = [];
  List<RegistrationModel> filteredRegistrations = [];
  bool isLoading = true;
  bool showOnlyDIT = false;
  bool showOnlyPaid = false;

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
          filteredRegistrations = List.from(eventRegistrations);
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

  void _applyFilters() {
    setState(() {
      filteredRegistrations = eventRegistrations.where((registration) {
        final isDITMatch =
            !showOnlyDIT || registration.college == 'DIT University';
        final isPaidMatch = !showOnlyPaid || registration.payment.paid;
        return isDITMatch && isPaidMatch;
      }).toList();
    });
  }

  Future<void> _generateCSV() async {
    if (await _checkPermissions()) {
      List<List<dynamic>> rows = [];

      List<String> headers = [
        'Team Name',
        'Email',
        'College',
        'Payment Status',
        'Amount'
      ];

      int maxMembers = filteredRegistrations
          .map((json) => json.members.length)
          .fold(0, (prev, curr) => curr > prev ? curr : prev);

      for (int i = 1; i <= maxMembers; i++) {
        headers.addAll([
          'Member $i Name',
          'Member $i College ID',
          'Member $i Personal ID',
        ]);
      }

      rows.add(headers);

      for (var regModel in filteredRegistrations) {
        List<dynamic> row = [
          regModel.teamName,
          regModel.email,
          regModel.college,
          regModel.payment.paid ? 'Paid' : 'Not Paid',
          regModel.payment.amount,
        ];

        for (int i = 0; i < maxMembers; i++) {
          if (i < regModel.members.length) {
            Member member = regModel.members[i];
            row.addAll([
              member.name,
              member.collegeId,
              member.personalId,
            ]);
          } else {
            row.addAll(['', '', '']);
          }
        }

        rows.add(row);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync(recursive: true);
      }

      final fileName =
          '${widget.eventName.replaceAll(" ", "_")}_registrations.csv';
      final filePath = path.join(downloadsDirectory.path, fileName);
      final File file = File(filePath);

      await file.writeAsString(csv);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('CSV file generated successfully at: $filePath')),
      );
    }
  }

  Future<bool> _checkPermissions() async {
    var status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    }
    status = await Permission.storage.request();
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

  double _calculateTotalAmount() {
    return filteredRegistrations
        .where((registration) => registration.payment.paid)
        .fold(0.0, (sum, registration) {
      double amount = double.tryParse(registration.payment.amount) ?? 0.0;
      return sum + amount;
    });
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
                    filteredRegistrations.length.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRegistrations.isEmpty
              ? const Center(
                  child: Text('No registrations found for this event.'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: _generateCSV,
                                child: const Text('Print Candidates'),
                              ),
                              const SizedBox(width: 2),
                              FilterChip(
                                label: const Text("DIT University"),
                                selected: showOnlyDIT,
                                onSelected: (value) {
                                  setState(() {
                                    showOnlyDIT = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                              const SizedBox(width: 2),
                              FilterChip(
                                label: const Text("Paid Only"),
                                selected: showOnlyPaid,
                                onSelected: (value) {
                                  setState(() {
                                    showOnlyPaid = value;
                                    _applyFilters();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (showOnlyPaid)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Total Amount: Rs ${_calculateTotalAmount().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          itemCount: filteredRegistrations.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 16),
                              child: DetailsCard(
                                  details: filteredRegistrations[index]),
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
        Text('Email: ${details.email}'),
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
      children: List.generate(members.length, (index) {
        Member member = members[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member ${index + 1}:'),
            Text('  Name: ${member.name}'),
            Text('  College ID: ${member.collegeId}'),
            Text('  Personal ID: ${member.personalId}'),
          ],
        );
      }),
    );
  }
}
