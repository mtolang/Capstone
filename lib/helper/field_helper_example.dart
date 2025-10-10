import 'package:capstone_2/helper/field_helper.dart';

/// Example usage and testing of FieldHelper
class FieldHelperExample {
  /// Test method to demonstrate FieldHelper usage
  static void testFieldHelper() {
    print('🧪 Testing FieldHelper with different data formats...\n');

    // Test case 1: ParentsAcc format (like your Firebase screenshots)
    Map<String, dynamic> parentData1 = {
      'Address': 'Indangan, Davao City Davao Del Sur',
      'Contact_Number': '09098766754',
      'Email': 'mtolang@gmail.com',
      'Full_Name': 'Martin Tols',
      'Password': '123456',
      'User_Name': 'Martin Rey',
    };

    // Test case 2: Alternative naming format
    Map<String, dynamic> parentData2 = {
      'address': 'Some address',
      'contactNumber': '09123456789',
      'email': 'test@email.com',
      'Name': 'John Doe',
      'password': '654321',
      'userName': 'johndoe',
    };

    // Test case 3: ClinicAcc format
    Map<String, dynamic> clinicData = {
      'Address': 'bst',
      'Clinic_Name': 'Andrew Therapy',
      'Contact_Number': '11022001',
      'Email': 'a@gmail.com',
      'Password': '200031',
      'User_Name': 'Andrew',
    };

    // Test case 4: TherapistAcc format
    Map<String, dynamic> therapistData = {
      'Address': 'Tagum Davao City',
      'Contact_Number': '09998767554',
      'Email': 'r@gmail.com',
      'Full_Name': 'Rhaynan Dave',
      'Password': '654321',
      'User_Name': 'Nanan',
    };

    print('=== Testing getName() ===');
    print('Parent Data 1 name: ${FieldHelper.getName(parentData1)}');
    print('Parent Data 2 name: ${FieldHelper.getName(parentData2)}');
    print('Clinic Data name: ${FieldHelper.getName(clinicData)}');
    print('Therapist Data name: ${FieldHelper.getName(therapistData)}');

    print('\n=== Testing getClinicName() ===');
    print('Clinic name: ${FieldHelper.getClinicName(clinicData)}');

    print('\n=== Testing getTherapistName() ===');
    print('Therapist name: ${FieldHelper.getTherapistName(therapistData)}');

    print('\n=== Testing getContactNumber() ===');
    print('Parent contact 1: ${FieldHelper.getContactNumber(parentData1)}');
    print('Parent contact 2: ${FieldHelper.getContactNumber(parentData2)}');
    print('Clinic contact: ${FieldHelper.getContactNumber(clinicData)}');
    print('Therapist contact: ${FieldHelper.getContactNumber(therapistData)}');

    print('\n=== Testing getEmail() ===');
    print('Parent email 1: ${FieldHelper.getEmail(parentData1)}');
    print('Parent email 2: ${FieldHelper.getEmail(parentData2)}');
    print('Clinic email: ${FieldHelper.getEmail(clinicData)}');
    print('Therapist email: ${FieldHelper.getEmail(therapistData)}');

    print('\n=== Testing getUsername() ===');
    print('Parent username 1: ${FieldHelper.getUsername(parentData1)}');
    print('Parent username 2: ${FieldHelper.getUsername(parentData2)}');
    print('Clinic username: ${FieldHelper.getUsername(clinicData)}');
    print('Therapist username: ${FieldHelper.getUsername(therapistData)}');

    print('\n=== Debug Field Printing ===');
    FieldHelper.debugPrintFields(parentData1, 'ParentsAcc');
    print('');
    FieldHelper.debugPrintFields(clinicData, 'ClinicAcc');
  }
}
