// ignore_for_file: avoid_print, prefer_const_constructors, use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_membership_app/screens/age_distribution_pie_chart.dart';
import 'package:gym_membership_app/screens/membership_pie_chart.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gym_membership_app/main.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final storage = const FlutterSecureStorage();
  String? _scannedEmail;
  String? _scannedMembershipStatus;
  String? _scannedExpires;
  String? _scannedFirstName;
  String? _scannedLastName;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isScannerOpen = false;

  Future<void> _extendMembership() async {
    if (_scannedEmail == null) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final newExpirationDate = DateTime.now().add(const Duration(days: 30));
      final formattedDate = newExpirationDate
          .toIso8601String()
          .split('T')[0]; // Format date only (YYYY-MM-DD)

      final url = Uri.parse(
          'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/extend-membership');
      final response = await http.post(
        url,
        body: json.encode({
          'email': _scannedEmail,
          'expires': formattedDate,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);
      if (responseData['statusCode'] == 200) {
        setState(() {
          _scannedMembershipStatus = 'Active';
          _scannedExpires = formattedDate;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to extend membership');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      safePrint('Error extending membership: $e');
    }
  }

  Future<void> _showMembersModal() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse(
          'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/get-members');
      final response = await http.get(url);
      final responseData = jsonDecode(response.body);

      if (responseData['statusCode'] == 200) {
        final List<dynamic> members = responseData['members'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Members List'),
              content: SingleChildScrollView(
                child: Column(
                  children: members.map<Widget>((member) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${member['firstName']} ${member['lastName']}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Email: ${member['email']}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Status: ${member['membershipStatus']}'),
                                Text('Expires: ${member['expires']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to fetch members');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      safePrint('Error fetching members: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanQRCode(BuildContext context) async {
    setState(() {
      _isScannerOpen = true;
    });

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 350,
            width: 300,
            child: MobileScanner(
              controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates),
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? rawValue = barcodes.first.rawValue;

                  if (rawValue != null) {
                    final List<String> qrData = rawValue.split(',');

                    if (qrData.length == 5) {
                      setState(() {
                        _scannedEmail = qrData[0];
                        _scannedFirstName = qrData[1];
                        _scannedLastName = qrData[2];
                        _scannedMembershipStatus = qrData[3];
                        _scannedExpires = qrData[4];
                        _isScannerOpen = false;
                      });

                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() {
                          _isScannerOpen = false;
                        });
                        Navigator.of(context).pop();
                      });
                      //Navigator.of(context).pop();
                    } else {
                      safePrint("QR code data format is incorrect.");
                    }
                  }
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isScannerOpen = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    setState(() {
      _isScannerOpen = false;
    });
  }

  Future<void> _showStatisticsModal(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse(
          'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/get-members');
      final response = await http.get(url);
      final responseData = jsonDecode(response.body);

      if (responseData['statusCode'] == 200) {
        final List<dynamic> members = responseData['members'];

        // Calculate statistics
        int totalMembers = members.length;
        int activeMembers = members
            .where((member) =>
                member['membershipStatus']?.toLowerCase() == 'active')
            .length;
        int expiredMembers = totalMembers - activeMembers;

        // Age distribution (grouped by age ranges)
        Map<String, int> ageDistribution = {
          '18-25': 0,
          '26-35': 0,
          '36-45': 0,
          '46-60': 0,
          '60+': 0,
        };
        for (var member in members) {
          if (member['dob'] != null) {
            final dob = DateTime.parse(member['dob']);
            final age = DateTime.now().year - dob.year;

            if (age >= 18 && age <= 25) {
              ageDistribution['18-25'] = ageDistribution['18-25']! + 1;
            } else if (age >= 26 && age <= 35) {
              ageDistribution['26-35'] = ageDistribution['26-35']! + 1;
            } else if (age >= 36 && age <= 45) {
              ageDistribution['36-45'] = ageDistribution['36-45']! + 1;
            } else if (age >= 46 && age <= 60) {
              ageDistribution['46-60'] = ageDistribution['46-60']! + 1;
            } else if (age > 60) {
              ageDistribution['60+'] = ageDistribution['60+']! + 1;
            }
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatsPage(
              totalMembers: totalMembers,
              activeMembers: activeMembers,
              expiredMembers: expiredMembers,
              ageDistribution: ageDistribution,
            ),
          ),
        );
      } else {
        throw Exception('Failed to fetch statistics');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      safePrint('Error fetching statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 192, 135, 235),
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                try {
                  await Amplify.Auth.signOut();
                  await storage.delete(key: 'userData');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to logout: $e')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _hasError
                ? const Text('Error extending membership.')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                            _isScannerOpen ? null : () => _scanQRCode(context),
                        child: const Text('Open QR Scanner'),
                      ),
                      const SizedBox(height: 20),
                      _scannedEmail != null
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: const Color.fromARGB(
                                        255, 192, 135, 235),
                                    width: 2),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Name: $_scannedFirstName $_scannedLastName',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 16),
                                      children: [
                                        const TextSpan(
                                          text: 'Status: ',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: _scannedMembershipStatus ??
                                              'Expired',
                                          style: TextStyle(
                                            color: (_scannedMembershipStatus
                                                        ?.toLowerCase() ==
                                                    'active')
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                        if (_scannedMembershipStatus
                                                ?.toLowerCase() ==
                                            'active')
                                          TextSpan(
                                            text:
                                                ' (Expires: $_scannedExpires)',
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_scannedMembershipStatus == 'Expired')
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _extendMembership,
                                      child: const Text('Extend Membership'),
                                    ),
                                ],
                              ),
                            )
                          : const Text('Scan a member\'s QR code'),
                    ],
                  ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'showMembers',
              onPressed: _showMembersModal,
              child: const Icon(Icons.people),
            ),
          ),
          Positioned(
            bottom: 90,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'statistics',
              onPressed: () => _showStatisticsModal(context),
              child: const Icon(Icons.bar_chart),
            ),
          ),
        ],
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;
  final Map<String, int> ageDistribution;

  const StatsPage({
    super.key,
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
    required this.ageDistribution,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /*Text(
              'Membership Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),*/
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color
                borderRadius: BorderRadius.circular(15), // Rounded edges
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(255, 192, 135, 235),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2), // Shadow position
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.all(16.0), // Padding inside the container
              child: Column(
                children: [
                  Text(
                    'Membership Statistics',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: MembershipPieChart(
                      totalMembers: totalMembers,
                      activeMembers: activeMembers,
                      expiredMembers: expiredMembers,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            /*Text(
              'Age Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),*/
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white, // Background color
                borderRadius: BorderRadius.circular(15), // Rounded edges
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(255, 192, 135, 235),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2), // Shadow position
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Age Distribution',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 250,
                    child: AgeDistributionPieChart(
                      ageDistribution: ageDistribution,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
