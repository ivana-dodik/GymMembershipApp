// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gym_membership_app/main.dart';
import 'package:gym_membership_app/screens/profile_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Retrieve user attributes
      final attributes = await Amplify.Auth.fetchUserAttributes();

      // Find the email attribute
      final emailAttribute = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.email,
        orElse: () => const AuthUserAttribute(
            userAttributeKey: CognitoUserAttributeKey.email, value: ''),
      );

      final email = emailAttribute.value;

      safePrint("User email: $email");

      final url = Uri.parse(
          'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/fetch');
      final response = await http.post(
        url,
        body: json.encode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      // Debugging information
      safePrint('Response status: ${response.statusCode}');
      safePrint('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (responseData['statusCode'] == 200) {
        setState(() {
          _userData = responseData['userData'] ?? {};
          storage.write(key: 'userData', value: jsonEncode(_userData));
          _isLoading = false; // Set _isLoading to false when data is loaded
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      safePrint('Error loading user data: $e');
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                if (_userData != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userData: _userData!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User data is not available yet.'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                try {
                  await Amplify.Auth.signOut();
                  await storage.delete(
                      key: 'userData'); // Clear stored user data

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (route) => false, // This removes all previous routes
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
                ? const Text('Error loading user data.')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          //color: const Color(0xFF87CEEB),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: const Color.fromARGB(255, 192, 135, 235),
                              width: 2),
                        ),
                        child: QrImageView(
                          data:
                              '${_userData!['email']},${_userData!['firstName']},${_userData!['lastName']},${_userData!['membershipStatus']},${_userData!['expires']}',
                          size: 300.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // User Data Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: 350,
                        decoration: BoxDecoration(
                          //color: const Color(0xFF87CEEB),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: const Color.fromARGB(255, 192, 135, 235),
                              width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${_userData?['firstName'] ?? 'No Name'} ${_userData?['lastName'] ?? 'No Last Name'}',
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
                                    text:
                                        '${_userData?['membershipStatus'] ?? 'Expired'}',
                                    style: TextStyle(
                                      color: (_userData?['membershipStatus'] ==
                                              'Active')
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  if (_userData?['membershipStatus'] ==
                                      'Active')
                                    TextSpan(
                                      text:
                                          ' (Expires: ${_userData?['expires'] ?? 'No Expiration'})',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
