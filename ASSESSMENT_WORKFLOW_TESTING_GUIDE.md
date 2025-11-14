# Assessment Workflow Testing Guide

## Date: November 14, 2025

## Complete User Flow: From Assessment to Folder Menu

This guide covers the complete workflow for both Initial Assessments and Final Evaluations appearing in the folder icon menu.

---

## 🎯 Workflow 1: Initial Assessment (First Assessment)

### Step 1: Assess Client from Patient List
1. **Navigate to**: Clinic → Patient List
2. **Find a patient** without any existing assessments (or create a new patient)
3. **Click**: "Assess Client" button on the patient card
4. **Fill out** the OT Assessment form:
   - Child information
   - Fine Motor Skills ratings
   - Gross Motor Skills ratings
   - Sensory Processing ratings
   - Cognitive Skills ratings
   - Notes for each section
5. **Click**: Submit/Save button
6. **Expected Result**: ✅ "Assessment saved successfully!" message

### Step 2: View Initial Assessment in Folder Menu
1. **Navigate to**: Clinic → Progress Reports
2. **Find the patient** you just assessed (should appear in the list)
3. **Click**: "View" button for that patient
4. **Look for**: Folder icon (📁) in the top-right corner of the screen
5. **Click**: The folder icon
6. **Expected Result**: ✅ Dialog opens with:
   - **"FIRST ASSESSMENT"** section at the top
   - **View Assessment** button (eye icon)
   - **Print Assessment** button (printer icon)
   - Assessment should NOT show "No initial assessment available"

### Step 3: Verify Assessment Content
1. **Click**: "View Assessment" button
2. **Expected Result**: ✅ Opens the assessment viewer showing:
   - Patient information
   - All skill ratings you entered
   - Notes you added
   - Creation timestamp

---

## 🎯 Workflow 2: Final Evaluation

### Step 1: Navigate to Progress Reports
1. **Navigate to**: Clinic → Progress Reports
2. **Select a patient** who has at least one assessment
3. **Click**: "View" button for that patient

### Step 2: Create Final Evaluation
1. In the patient's progress detail page, **look for**:
   - Folder icon in top-right (this is where final evaluation will appear after creation)
   - Final Evaluation section in the page body
2. **Click**: "Create Final Evaluation" button (usually at bottom of page)
3. **Fill out** the Final Evaluation form:
   - Overall Summary
   - Therapy Goals Achieved
   - Overall Progress Rating
   - Progress Description
   - Skills Development sections:
     - Fine Motor Evaluation
     - Gross Motor Evaluation
     - Cognitive Evaluation
     - Sensory Evaluation
     - Social Emotional Evaluation
   - Recommendations:
     - Continue Therapy Recommendation
     - Home Exercise Program
     - School Recommendations
     - Follow-Up Schedule
     - Additional Services
     - Parent Guidelines
   - Discharge Planning (if applicable):
     - Discharge Recommendation checkbox
     - Discharge Reason
     - Maintenance Plan
   - Professional Information:
     - Therapist Notes
     - Therapist Name
     - Therapist License
4. **Click**: Submit/Save button
5. **Expected Result**: ✅ "Final evaluation saved successfully!" message

### Step 3: View Final Evaluation in Folder Menu
1. **Stay on the same page** OR **Navigate back to** Progress Reports → View patient
2. **Click**: Folder icon (📁) in top-right corner
3. **Expected Result**: ✅ Dialog opens with:
   - **"FIRST ASSESSMENT"** section (if available)
   - **"FINAL EVALUATION"** section
   - Under Final Evaluation:
     - **View Evaluation** button (eye icon)
     - **Print/Download** button (printer icon)
     - **Create New Evaluation** button (plus icon)

### Step 4: Verify Final Evaluation Content
1. **Click**: "View Evaluation" button
2. **Expected Result**: ✅ Opens the final evaluation viewer showing:
   - Patient information
   - Session summary
   - Overall assessment
   - All skill evaluations you entered
   - Recommendations
   - Discharge planning (if applicable)
   - Professional information
   - Creation timestamp

---

## 🐛 Troubleshooting

### Issue: "No initial assessment available" shows in folder menu

**Possible Causes**:
1. Assessment was created before the `isInitialAssessment` field was implemented
2. Database needs migration

**Solution**:
Run the migration script to fix existing assessments:
```bash
cd d:\newkind\accept-rev\Capstone
flutter run migrate_initial_assessments.dart
```

After migration completes:
- Hot reload the app (press 'r' in terminal)
- Or restart the app completely
- Navigate back to Progress Reports
- The initial assessment should now appear

### Issue: Final Evaluation doesn't appear in folder menu

**This has been FIXED**. The query was looking for `patientId` but should use `clientId`.

**To verify the fix is applied**:
1. Check if you see debug logs in the console when opening folder menu
2. Look for: `🔍 Loading final evaluations for clientId: ...`
3. Should show: `✅ Loaded X final evaluations`

**If still not working**:
1. Make sure you hot reloaded or restarted the app after the fix
2. Check that the final evaluation was actually saved (go to the form and verify submission succeeded)
3. Check console logs for any error messages

### Issue: Assessment count shows 0 but assessment was created

**Check**:
1. Console logs: Look for `🔍 Getting OT assessments count for clientId: ...`
2. Verify the `clinicId` is correct (should be "CLI01")
3. Make sure assessment was saved to correct collection (`OTAssessments`)

---

## 📊 Debug Output Reference

### When loading Progress Reports page:
```
🔍 Getting OT assessments count for clientId: QRR21w3kD7MoI0AQ76Nw, clinicId: CLI01
🔍 OT assessments count query returned: 4 documents
```

### When opening folder menu (Initial Assessment):
```
🔍 Loading initial assessment for clientId: QRR21w3kD7MoI0AQ76Nw, clinicId: CLI01
🔍 Total assessments found: 4
🔍 Assessment ID: abc123
   - isInitialAssessment: true
   - patientId: QRR21w3kD7MoI0AQ76Nw
   - createdAt: Timestamp(seconds=1762841640, nanoseconds=0)
✅ Initial assessment loaded: abc123
```

### When opening folder menu (Final Evaluation):
```
🔍 Loading final evaluations for clientId: dxJiDOGb9TM62TX6gJ6U, clinicId: CLI01
🔍 Final evaluations query returned: 2 documents
🔍 Final Evaluation ID: def456
   - clientId: dxJiDOGb9TM62TX6gJ6U
   - clinicId: CLI01
   - createdAt: Timestamp(seconds=1762972076, nanoseconds=38000000)
✅ Loaded 2 final evaluations
```

---

## ✅ Complete Testing Checklist

### Initial Assessment Flow:
- [ ] Can access "Assess Client" from Patient List
- [ ] Assessment form loads properly
- [ ] Can fill out all sections
- [ ] Assessment saves successfully
- [ ] Patient appears in Progress Reports with assessment count > 0
- [ ] Can click "View" button for patient
- [ ] Folder icon appears in top-right
- [ ] Clicking folder icon shows dialog
- [ ] "FIRST ASSESSMENT" section appears in dialog
- [ ] "View Assessment" button works
- [ ] "Print Assessment" button works
- [ ] Assessment content displays correctly

### Final Evaluation Flow:
- [ ] Can navigate to patient's progress detail page
- [ ] "Create Final Evaluation" button is visible
- [ ] Final evaluation form loads properly
- [ ] Can fill out all sections
- [ ] Final evaluation saves successfully
- [ ] Folder icon appears in top-right (or page reloads showing it)
- [ ] Clicking folder icon shows dialog
- [ ] "FINAL EVALUATION" section appears in dialog
- [ ] "View Evaluation" button works
- [ ] "Print/Download" button works
- [ ] "Create New Evaluation" button works (for additional evaluations)
- [ ] Final evaluation content displays correctly

### Debug Logging:
- [ ] Console shows assessment count queries
- [ ] Console shows initial assessment loading logs
- [ ] Console shows final evaluation loading logs
- [ ] No error messages in console
- [ ] All queries return expected document counts

---

## 🎓 Understanding the Data Flow

### Initial Assessment:
1. **Create**: Patient List → Assess Client → Fill form → Save
   - Saved to: `OTAssessments` collection
   - Field set: `isInitialAssessment: true` (for first assessment)
   - Field set: `patientId: <patient_id>`

2. **Display**: Progress Reports → View Patient → Folder Icon
   - Queries: `OTAssessments` collection
   - Filter: `patientId == <patient_id> AND clinicId == <clinic_id> AND isInitialAssessment == true`
   - Shows in: "FIRST ASSESSMENT" section

### Final Evaluation:
1. **Create**: Progress Reports → View Patient → Create Final Evaluation → Fill form → Save
   - Saved to: `FinalEvaluations` collection
   - Field set: `isFinalEvaluation: true`
   - Field set: `clientId: <client_id>` ⚠️ Note: Uses `clientId`, not `patientId`

2. **Display**: Progress Reports → View Patient → Folder Icon
   - Queries: `FinalEvaluations` collection
   - Filter: `clientId == <client_id> AND clinicId == <clinic_id>`
   - Shows in: "FINAL EVALUATION" section

---

## 📝 Notes

### Field Name Differences:
- **OTAssessments**: Uses `patientId`
- **FinalEvaluations**: Uses `clientId`
- Both refer to the same patient, just different field names

### Migration Script:
- Only needed for assessments created BEFORE the `isInitialAssessment` field was added
- New assessments automatically get the field
- Script is safe to run multiple times (skips already-migrated assessments)

### Multiple Final Evaluations:
- A patient can have multiple final evaluations
- Each appears as a separate item in the folder menu
- "Create New Evaluation" button allows adding more

### Permissions:
- Only clinic therapists can create assessments and evaluations
- Parents can only view (if/when viewing permissions are implemented)

---

## 🔗 Related Documentation
- `ASSESSMENT_MENU_BUG_FIXES.md` - Technical details of recent fixes
- `CATEGORIZED_ASSESSMENT_MENU.md` - Original folder menu implementation
- `INITIAL_AND_FINAL_ASSESSMENT_IMPLEMENTATION.md` - Assessment tracking system
- `SESSION_MANAGEMENT_DOCUMENTATION.md` - Overall session architecture
