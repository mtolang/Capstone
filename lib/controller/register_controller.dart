import 'package:flutter/material.dart';
import '../helper/clinic_auth.dart';

class RegisterParentUser {
  Future<void> registerParentUser(
    BuildContext context,
    String fullName,
    String userName,
    String email,
    String contactNumber,
    String address,
    String password,
    String passwordConfirm,
  ) async {
    try {
      // Validate inputs
      if (fullName.isEmpty ||
          userName.isEmpty ||
          email.isEmpty ||
          contactNumber.isEmpty ||
          address.isEmpty ||
          password.isEmpty) {
        _showErrorDialog(context, 'Please fill in all required fields.');
        return;
      }

      if (password != passwordConfirm) {
        _showErrorDialog(context, 'Passwords do not match.');
        return;
      }

      if (!ClinicAuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!ClinicAuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Save parent registration data to ParentsReg collection
      final result = await ClinicAuthService.saveParentRegistration(
        fullName: fullName,
        userName: userName,
        email: email,
        contactNumber: contactNumber,
        address: address,
        password: password,
      );

      // Show success message and navigate
      if (result != null && result['success'] == true) {
        _showSuccessDialog(context,
            'Parent registration saved successfully! Document ID: ${result['documentId']}');
      } else {
        _showErrorDialog(context, 'Failed to save parent registration data.');
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class RegisterTherapistUser {
  Future<void> registerTherapistUser(
    BuildContext context,
    String fullName,
    String userName,
    String email,
    String contactNumber,
    String address,
    String password,
    String passwordConfirm,
  ) async {
    try {
      // Validate inputs
      if (fullName.isEmpty ||
          userName.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        _showErrorDialog(context, 'Please fill in all required fields.');
        return;
      }

      if (password != passwordConfirm) {
        _showErrorDialog(context, 'Passwords do not match.');
        return;
      }

      if (!ClinicAuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!ClinicAuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Register user
      await ClinicAuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: contactNumber,
      );

      // Show success message and navigate
      _showSuccessDialog(
          context, 'Registration successful! Please login to continue.');
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/loginas', (route) => false);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class RegisterClinicUser {
  Future<void> registerClinicUser(
    BuildContext context,
    String clinicName,
    String userName,
    String email,
    String contactNumber,
    String address,
    String password,
    String passwordConfirm,
  ) async {
    try {
      // Validate inputs
      if (clinicName.isEmpty ||
          userName.isEmpty ||
          email.isEmpty ||
          contactNumber.isEmpty ||
          address.isEmpty ||
          password.isEmpty) {
        _showErrorDialog(context, 'Please fill in all required fields.');
        return;
      }

      if (password != passwordConfirm) {
        _showErrorDialog(context, 'Passwords do not match.');
        return;
      }

      if (!ClinicAuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!ClinicAuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Save clinic registration data to ClinicReg collection
      final result = await ClinicAuthService.saveClinicRegistration(
        clinicName: clinicName,
        userName: userName,
        email: email,
        contactNumber: contactNumber,
        address: address,
        password: password,
      );

      // Show success message and navigate
      if (result != null && result['success'] == true) {
        _showSuccessDialog(context,
            'Clinic registration saved successfully! Document ID: ${result['documentId']}');
      } else {
        _showErrorDialog(context, 'Failed to save clinic registration data.');
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
