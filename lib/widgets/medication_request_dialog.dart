import 'package:flutter/material.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';

class MedicationRequestDialog extends StatefulWidget {
  final Pharmacy pharmacy;
  final ApiService apiService;

  const MedicationRequestDialog({
    Key? key,
    required this.pharmacy,
    required this.apiService,
  }) : super(key: key);

  @override
  _MedicationRequestDialogState createState() => _MedicationRequestDialogState();
}

class _MedicationRequestDialogState extends State<MedicationRequestDialog> {
  final _medicationController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _medicationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_medicationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a medication name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = await widget.apiService.createMedicationRequest(
        _medicationController.text,
        _noteController.text.isEmpty ? null : _noteController.text,
        widget.pharmacy,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request sent successfully'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/medication-requests/${request.id}',
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _medicationController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                hintText: 'Enter medication name',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Enter any additional information (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendRequest,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }
}
