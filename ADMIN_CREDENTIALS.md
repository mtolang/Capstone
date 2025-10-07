# Admin Account Information

## 🔐 Admin Login Credentials

**Username:** `Admin`  
**Password:** `adanbayot`

## 🚪 How to Access Admin Panel

1. **Launch the app**
2. **Navigate to login selection** (login_as.dart)
3. **Tap the Kindora logo 3 times quickly** (Easter egg activation)
4. **Select "Admin Login"** from the SnackBar
5. **Enter credentials:**
   - Username: `Admin`
   - Password: `adanbayot`
6. **Access the full admin dashboard**

## 🛡️ Security Features

- **Hardcoded credentials** - Only one admin account exists
- **Hidden access** - Admin login only accessible via secret 3-tap gesture
- **Secure validation** - Exact match required for username and password
- **Session-based** - No persistent login storage

## 📊 Admin Dashboard Features

- **User Management** for all user types:
  - Carers/Parents (ParentsReg → ParentsAcc)
  - Clinics (ClinicReg → ClinicAcc)  
  - Therapists (TherapistReg → TherapistAcc)
- **Real-time Firebase integration**
- **Accept/Reject pending registrations**
- **View detailed user profiles**
- **Remove accepted users**

## ⚠️ Important Notes

- **Single Admin Account**: Only the specified credentials will work
- **Case Sensitive**: Username "Admin" must be exact (capital A)
- **No Registration**: Admin account is hardcoded, no signup process
- **Secure Access**: 3-tap easter egg prevents unauthorized discovery