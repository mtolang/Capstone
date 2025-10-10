/// Helper class for handling different field name variations in Firestore documents
/// This addresses the issue where different collections use different naming conventions
class FieldHelper {
  /// Gets a value from a data map trying multiple possible field names
  /// Returns the first non-null, non-empty value found, or null if none found
  static String? getFlexibleValue(
      Map<String, dynamic> data, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty) {
        return data[key].toString().trim();
      }
    }
    return null;
  }

  /// Common field name variations for names
  static List<String> get nameFields => [
        'Name',
        'Full_Name',
        'Full Name',
        'name',
        'full_name',
        'PatientName',
        'patient_name',
        'UserName',
        'user_name',
        'User_Name'
      ];

  /// Common field name variations for clinic names
  static List<String> get clinicNameFields => [
        'Clinic_Name',
        'Clinic Name',
        'clinicName',
        'clinic_name',
        'Name',
        'Full_Name',
        'Full Name',
        'ClinicName'
      ];

  /// Common field name variations for therapist names
  static List<String> get therapistNameFields => [
        'Full_Name',
        'Full Name',
        'Name',
        'name',
        'TherapistName',
        'therapist_name',
        'Therapist_Name'
      ];

  /// Common field name variations for contact numbers
  static List<String> get contactNumberFields => [
        'Contact_Number',
        'Contact Number',
        'contactNumber',
        'contact_number',
        'PhoneNumber',
        'phone_number',
        'Phone_Number',
        'Mobile',
        'mobile'
      ];

  /// Common field name variations for email addresses
  static List<String> get emailFields => [
        'Email',
        'email',
        'Email_Address',
        'Email Address',
        'emailAddress',
        'email_address'
      ];

  /// Common field name variations for addresses
  static List<String> get addressFields => [
        'Address',
        'address',
        'Location',
        'location',
        'Street_Address',
        'Street Address',
        'streetAddress',
        'street_address'
      ];

  /// Common field name variations for user names/usernames
  static List<String> get usernameFields => [
        'User_Name',
        'User Name',
        'userName',
        'user_name',
        'Username',
        'username'
      ];

  /// Get name from data using common name field variations
  static String? getName(Map<String, dynamic> data) {
    return getFlexibleValue(data, nameFields);
  }

  /// Get clinic name from data using clinic-specific field variations
  static String? getClinicName(Map<String, dynamic> data) {
    return getFlexibleValue(data, clinicNameFields);
  }

  /// Get therapist name from data using therapist-specific field variations
  static String? getTherapistName(Map<String, dynamic> data) {
    return getFlexibleValue(data, therapistNameFields);
  }

  /// Get contact number from data using contact field variations
  static String? getContactNumber(Map<String, dynamic> data) {
    return getFlexibleValue(data, contactNumberFields);
  }

  /// Get email from data using email field variations
  static String? getEmail(Map<String, dynamic> data) {
    return getFlexibleValue(data, emailFields);
  }

  /// Get address from data using address field variations
  static String? getAddress(Map<String, dynamic> data) {
    return getFlexibleValue(data, addressFields);
  }

  /// Get username from data using username field variations
  static String? getUsername(Map<String, dynamic> data) {
    return getFlexibleValue(data, usernameFields);
  }

  /// Debug method to print all available fields in a document
  static void debugPrintFields(
      Map<String, dynamic> data, String collectionName) {
    print('🔍 DEBUG: Available fields in $collectionName:');
    data.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });
  }
}
