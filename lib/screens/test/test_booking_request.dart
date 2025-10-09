import 'package:flutter/material.dart';
import 'package:kindora/services/clinic_schedule_service.dart';

class TestBookingRequestPage extends StatefulWidget {
  const TestBookingRequestPage({Key? key}) : super(key: key);

  @override
  State<TestBookingRequestPage> createState() => _TestBookingRequestPageState();
}

class _TestBookingRequestPageState extends State<TestBookingRequestPage> {
  final _parentNameController = TextEditingController(text: 'Maria Santos');
  final _childNameController = TextEditingController(text: 'Sofia Santos');
  final _dayController = TextEditingController(text: 'Monday');
  final _timeController = TextEditingController(text: '10:00 AM');
  final _typeController = TextEditingController(text: 'Speech Therapy');
  final _parentIdController = TextEditingController(text: 'PAR001');

  bool _isLoading = false;

  Future<void> _createTestRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ClinicScheduleService.saveBookingRequest(
        parentName: _parentNameController.text,
        childName: _childNameController.text,
        requestedDay: _dayController.text,
        requestedTime: _timeController.text,
        appointmentType: _typeController.text,
        parentId: _parentIdController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test booking request created successfully!'),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Booking Request'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _parentNameController,
              decoration: const InputDecoration(
                labelText: 'Parent Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _childNameController,
              decoration: const InputDecoration(
                labelText: 'Child Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dayController,
              decoration: const InputDecoration(
                labelText: 'Requested Day',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Requested Time',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Appointment Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _parentIdController,
              decoration: const InputDecoration(
                labelText: 'Parent ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTestRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Test Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _childNameController.dispose();
    _dayController.dispose();
    _timeController.dispose();
    _typeController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }
}
