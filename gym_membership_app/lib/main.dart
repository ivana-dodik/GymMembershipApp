// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:gym_membership_app/screens/employee_home_screen.dart';
import 'package:gym_membership_app/screens/user_home_screen.dart';
import 'package:http/http.dart' as http;

import 'amplifyconfiguration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugin(auth);
      await Amplify.configure(amplifyconfig);

      await Amplify.Auth.signOut();
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Authenticator(
      authenticatorBuilder: (BuildContext context, AuthenticatorState state) {
        switch (state.currentStep) {
          case AuthenticatorStep.signIn:
            return CustomScaffold(
              state: state,
              body: SignInForm(),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () => state.changeStep(
                      AuthenticatorStep.signUp,
                    ),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            );
          case AuthenticatorStep.signUp:
            return CustomScaffold(
              state: state,
              body: SignUpForm.custom(
                fields: [
                  SignUpFormField.email(required: true),
                  SignUpFormField.custom(
                    title: 'First Name',
                    attributeKey: CognitoUserAttributeKey.name,
                    required: true,
                  ),
                  SignUpFormField.custom(
                    title: 'Last Name',
                    attributeKey: CognitoUserAttributeKey.familyName,
                    required: true,
                  ),
                  SignUpFormField.password(),
                  SignUpFormField.passwordConfirmation(),
                  SignUpFormField.birthdate(required: true),
                ],
              ),
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => state.changeStep(
                      AuthenticatorStep.signIn,
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          /*case AuthenticatorStep.confirmSignUp:
            return CustomScaffold(
              state: state,
              body: ConfirmSignUpForm(),
            );
          case AuthenticatorStep.resetPassword:
            return CustomScaffold(
              state: state,
              body: ResetPasswordForm(),
            );
          case AuthenticatorStep.confirmResetPassword:
            return CustomScaffold(
              state: state,
              body: const ConfirmResetPasswordForm(),
            );*/
          default:
            return null; // For other steps, fall back to the prebuilt UI
        }
      },
      child: MaterialApp(
        builder: Authenticator.builder(),
        home: const AuthCheck(),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfSignedIn();
  }

  Future<void> _checkIfSignedIn() async {
    try {
      // Check if the user is already signed in
      // ignore: unused_local_variable
      final result = await Amplify.Auth.getCurrentUser();
      final userAttributes = await Amplify.Auth.fetchUserAttributes();
      final email = userAttributes
          .firstWhere(
              (attr) => attr.userAttributeKey == AuthUserAttributeKey.email)
          .value;

      await _checkUserRole(email);
    } catch (e) {
      safePrint('User not signed in or error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserRole(String email) async {
    final url = Uri.parse(
        'https://omgip6zode.execute-api.eu-north-1.amazonaws.com/dev/role');

    try {
      final response = await http.post(
        url,
        body: json.encode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final userRole = responseData['role'];

        if (userRole == 'employee') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const EmployeeHomeScreen()));
        } else if (userRole == 'user') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const UserHomeScreen()));
        }
      } else {
        safePrint('Failed to check role: ${responseData['message']}');
      }
    } catch (error) {
      safePrint('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Authenticator(
            child: MaterialApp(
              builder: Authenticator.builder(),
              home: const Scaffold(
                body: Center(child: Text('Welcome! Please login or sign up.')),
              ),
            ),
          );
  }
}

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    required this.state,
    required this.body,
    this.footer,
  });

  final AuthenticatorState state;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32),
                //child: Center(child: FlutterLogo(size: 100)),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png', // Replace with your image path
                    width: 100, // Adjust the size as needed
                    height: 100,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: body,
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: footer != null ? [footer!] : null,
    );
  }
}
