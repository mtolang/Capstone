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
        'childName',
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
        'parentPhone',
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
        'parentEmail',
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

  /// Get child name from childInfo field or fallback to standard name fields
  static String? getChildName(Map<String, dynamic> data) {
    // First try to get from patientInfo (your Firebase structure)
    if (data['patientInfo'] is Map<String, dynamic>) {
      final patientInfo = data['patientInfo'] as Map<String, dynamic>;
      if (patientInfo['childName'] != null) {
        return patientInfo['childName'].toString().trim();
      }
    }
    
    // Then try to get from childInfo sub-document
    if (data['childInfo'] is Map<String, dynamic>) {
      final childInfo = data['childInfo'] as Map<String, dynamic>;
      if (childInfo['childName'] != null) {
        return childInfo['childName'].toString().trim();
      }
    }
    
    // Fallback to direct childName field or standard name fields
    return getFlexibleValue(data, ['childName', ...nameFields]);
  }

  /// Get parent name from parentInfo field or fallback to standard name fields  
  static String? getParentName(Map<String, dynamic> data) {
    // First try direct parentName field (as shown in Firebase)
    if (data['parentName'] != null && data['parentName'].toString().trim().isNotEmpty) {
      return data['parentName'].toString().trim();
    }
    
    // Try to get from patientInfo (your Firebase structure)
    if (data['patientInfo'] is Map<String, dynamic>) {
      final patientInfo = data['patientInfo'] as Map<String, dynamic>;
      if (patientInfo['parentName'] != null) {
        return patientInfo['parentName'].toString().trim();
      }
    }
    
    // Try to get from parentInfo sub-document
    if (data['parentInfo'] is Map<String, dynamic>) {
      final parentInfo = data['parentInfo'] as Map<String, dynamic>;
      final parentName = getName(parentInfo);
      if (parentName != null) return parentName;
    }
    
    // Fallback to other parent field variations
    return getFlexibleValue(data, ['Parent_Name', 'parent_name', 'guardianName', 'guardian_name', ...nameFields]);
  }

  /// Get parent contact number specifically
  static String? getParentContact(Map<String, dynamic> data) {
    // First try direct parentPhone field
    if (data['parentPhone'] != null && data['parentPhone'].toString().trim().isNotEmpty) {
      return data['parentPhone'].toString().trim();
    }
    
    // Fallback to standard contact fields
    return getContactNumber(data);
  }

  /// Get parent email specifically
  static String? getParentEmail(Map<String, dynamic> data) {
    // First try direct parentEmail field
    if (data['parentEmail'] != null && data['parentEmail'].toString().trim().isNotEmpty) {
      return data['parentEmail'].toString().trim();
    }
    
    // Fallback to standard email fields
    return getEmail(data);
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
