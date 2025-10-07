import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    String passwordConfirm, {
    XFile? governmentIdFile,
  }) async {
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

      // Show loading dialog
      _showLoadingDialog(context, 'Saving registration data...');

      // Save parent registration data with file upload
      final result = await ClinicAuthService.saveParentRegistrationWithFile(
        fullName: fullName,
        userName: userName,
        email: email,
        contactNumber: contactNumber,
        address: address,
        password: password,
        governmentIdFile: governmentIdFile,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show success message and navigate
      if (result != null && result['success'] == true) {
        String message =
            'Parent registration saved successfully! Document ID: ${result['documentId']}';
        if (result['documentUrl'] != null) {
          message += '\nGovernment ID document uploaded successfully.';
        }
        _showSuccessDialog(context, message);
      } else {
        _showErrorDialog(context, 'Failed to save parent registration data.');
      }
    } catch (e) {
      // Hide loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(context, e.toString());
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
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
    String passwordConfirm, {
    XFile? documentFile,
  }) async {
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

      // Show loading dialog
      _showLoadingDialog(context, 'Saving registration data...');

      // Save clinic registration data with file upload
      final result = await ClinicAuthService.saveClinicRegistrationWithFile(
        clinicName: clinicName,
        userName: userName,
        email: email,
        contactNumber: contactNumber,
        address: address,
        password: password,
        documentFile: documentFile,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show success message and navigate
      if (result != null && result['success'] == true) {
        String message =
            'Clinic registration saved successfully! Document ID: ${result['documentId']}';
        if (result['documentUrl'] != null) {
          message += '\nRegistration document uploaded successfully.';
        }
        _showSuccessDialog(context, message);
      } else {
        _showErrorDialog(context, 'Failed to save clinic registration data.');
      }
    } catch (e) {
      // Hide loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(context, e.toString());
    }
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
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
