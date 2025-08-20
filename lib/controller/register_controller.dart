import 'package:flutter/material.dart';
import '../helper/auth.dart';

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
          password.isEmpty) {
        _showErrorDialog(context, 'Please fill in all required fields.');
        return;
      }

      if (password != passwordConfirm) {
        _showErrorDialog(context, 'Passwords do not match.');
        return;
      }

      if (!AuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!AuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Register user
      await AuthService.registerWithEmailAndPassword(
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

      if (!AuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!AuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Register user
      await AuthService.registerWithEmailAndPassword(
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
          password.isEmpty) {
        _showErrorDialog(context, 'Please fill in all required fields.');
        return;
      }

      if (password != passwordConfirm) {
        _showErrorDialog(context, 'Passwords do not match.');
        return;
      }

      if (!AuthService.isValidEmail(email)) {
        _showErrorDialog(context, 'Please enter a valid email address.');
        return;
      }

      if (!AuthService.isValidPassword(password)) {
        _showErrorDialog(
            context, 'Password must be at least 6 characters long.');
        return;
      }

      // Register user
      await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: userName,
        clinicName: clinicName,
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
