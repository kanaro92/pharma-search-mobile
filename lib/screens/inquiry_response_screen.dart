import 'package:flutter/material.dart';
import '../models/medication_inquiry.dart';
import '../services/api_service.dart';

class InquiryResponseScreen extends StatefulWidget {
  final ApiService apiService;
  final MedicationInquiry inquiry;

  const InquiryResponseScreen({
    Key? key,
    required this.apiService,
    required this.inquiry,
  }) : super(key: key);

  @override
  State<InquiryResponseScreen> createState() => _InquiryResponseScreenState();
}

class _InquiryResponseScreenState extends State<InquiryResponseScreen> {
  final _responseController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResponse() async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a response')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.respondToInquiry(
        widget.inquiry.id,
        _responseController.text,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending response: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respond to Inquiry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication: ${widget.inquiry.medicationName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Patient Note: ${widget.inquiry.patientNote}'),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${widget.inquiry.status}',
                      style: TextStyle(
                        color: widget.inquiry.status == 'PENDING'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                hintText: 'Enter your response to the patient...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResponse,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }
}
