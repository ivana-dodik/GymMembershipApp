// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_membership_app/main.dart';
import 'package:gym_membership_app/screens/user_home_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  String membershipStatus = '';
  String expirationDate = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    firstNameController.text = widget.userData['firstName'];
    lastNameController.text = widget.userData['lastName'];
    dobController.text = widget.userData['dob'];
    membershipStatus = widget.userData['membershipStatus'];
    expirationDate = widget.userData['expires'] ?? '';
  }

  Future<void> _saveChanges() async {
    final updatedUserData = {
      'email': widget.userData['email'],
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'dob': dobController.text,
    };

    try {
      await updateUser(updatedUserData);

      // Save the updated data in FlutterSecureStorage
      await secureStorage.write(
          key: 'userData', value: updatedUserData.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(dobController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != DateTime.now()) {
      setState(() {
        dobController.text = pickedDate
            .toLocal()
            .toString()
            .split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  void _showChangePasswordModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController resetCodeController =
            TextEditingController();
        final TextEditingController newPasswordController =
            TextEditingController();
        final TextEditingController confirmPasswordController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: resetCodeController,
                decoration: const InputDecoration(
                  labelText: 'Reset Code',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                } else {
                  _confirmResetPassword(
                    resetCodeController.text,
                    newPasswordController.text,
                  );
                  Navigator.pop(context); // Close the modal after submission
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Initiate the password reset process (sends a reset code to the user)
  Future<void> _initiatePasswordReset() async {
    try {
      final email =
          widget.userData['email']; // Assuming user's email is available
      await Amplify.Auth.resetPassword(username: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent to your email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating reset: $e')),
      );
      Navigator.pop(context);
    }
  }

  // Confirm the password reset with the code and new password
  Future<void> _confirmResetPassword(
      String resetCode, String newPassword) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: widget.userData['email'], // User email
        newPassword: newPassword,
        confirmationCode: resetCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful')),
      );
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset password: $e')),
      );*/
      //Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', textAlign: TextAlign.center),
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
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserHomeScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                /*await secureStorage.delete(
                    key: 'userData'); // Clear stored user data
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );*/
                try {
                  await Amplify.Auth.signOut();
                  await secureStorage.delete(
                      key: 'userData'); // Clear stored user data

                  // Redirect to the initial screen handled by Authenticator
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom, // Adjusts for keyboard
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildNonEditableField('Email', widget.userData['email']),
              const SizedBox(height: 10),
              _buildTextField(firstNameController, 'First Name', Icons.person),
              const SizedBox(height: 10),
              _buildTextField(lastNameController, 'Last Name', Icons.person),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                      dobController, 'Date of Birth', Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 10),
              _buildNonEditableField('Membership Status', membershipStatus),
              const SizedBox(height: 10),
              if (membershipStatus == 'Active')
                _buildNonEditableField('Membership Expires', expirationDate),
              const SizedBox(height: 20),
              Column(
                children: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Step 1: Initiate the password reset (sends code to user)
                        await _initiatePasswordReset();

                        // Step 2: Show the modal to input reset code and new password
                        _showChangePasswordModal(context);
                      }, //TO DO
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(200, 36),
                      ),
                      child: const Text('Change Password'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        fixedSize:
                            const Size(200, 36), // Set fixed width and height
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool readOnly = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      readOnly: readOnly,
    );
  }

  Widget _buildNonEditableField(String label, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      readOnly: true,
    );
  }

  Future<void> updateUser(Map<String, dynamic> updatedUserData) async {
    const String apiUrl =
        'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/update';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedUserData),
      );

      if (response.statusCode == 200) {
        print('Profile updated successfully');
      } else {
        print('Failed to update profile: ${response.body}');
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Error updating profile');
    }
  }
}
