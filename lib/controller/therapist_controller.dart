import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helper/clinic_auth.dart';

class RegisterTherapistUser {
  Future<void> registerTherapistUser(
    BuildContext context,
    String fullName,
    String userName,
    String email,
    String contactNumber,
    String address,
    String password,
    String passwordConfirm, {
    XFile? professionalIdFile,
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
      _showLoadingDialog(context, 'Saving therapist registration data...');

      // Save therapist registration data with file upload
      final result = await ClinicAuthService.saveTherapistRegistrationWithFile(
        fullName: fullName,
        userName: userName,
        email: email,
        contactNumber: contactNumber,
        address: address,
        password: password,
        professionalIdFile: professionalIdFile,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show success message and navigate
      if (result != null && result['success'] == true) {
        String message =
            'Therapist registration saved successfully! Document ID: ${result['documentId']}';
        if (result['documentUrl'] != null) {
          message += '\nProfessional ID document uploaded successfully.';
          print('✅ File upload successful: ${result['documentUrl']}');
        } else if (professionalIdFile != null) {
          message += '\n⚠️ Warning: Registration saved but file upload failed.';
          print('❌ File upload failed despite file being selected');
        }
        _showSuccessDialog(context, message);
      } else {
        String errorMessage = 'Failed to save therapist registration data.';
        if (result != null && result['error'] != null) {
          errorMessage += '\nError: ${result['error']}';
        }
        print('❌ Registration failed: $errorMessage');
        _showErrorDialog(context, errorMessage);
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
