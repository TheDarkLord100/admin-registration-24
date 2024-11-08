import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youthopia_admin_app/registration_screen_details.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';



class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List paymentData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPaymentData();
  }

  Future<void> fetchPaymentData() async {
    const url = 'https://27.123.248.68:4000/api/payment/getPayments';

    try {
      var client = http.Client();
      http.Response response = await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body) as List;
        setState(() {
          paymentData = decodedResponse;
          isLoading = false;
        });
      } else {
        throw HttpException('Failed to load payment data, status code: ${response.statusCode}');
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
        title: const Text('Payment Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentData.isEmpty
              ? const Center(child: Text('No payment data available'))
              : ListView.builder(
                  itemCount: paymentData.length,
                  itemBuilder: (context, index) {
                    final payment = paymentData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text('Order ID: ${payment['paymentInfo']['order_id'] ?? 'N/A'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment ID: ${payment['paymentInfo']['payment_id'] ?? 'N/A'}'),
                            Text('Email: ${payment['email'] ?? 'N/A'}'),
                            Text('Registration IDs: ${payment['registrationIds'].join(", ")}'),
                            Text('Payment Success: ${payment['paymentSuccess'] ? 'Yes' : 'No'}'),
                          ],
                        ),
                        onTap: () {
                          // Navigate to RegistrationDetailsScreen with registration IDs
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationDetailsScreen(
                                registrationIds: List<String>.from(payment['registrationIds']),
                              ),
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
